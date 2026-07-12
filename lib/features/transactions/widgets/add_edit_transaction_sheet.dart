import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/utils/friendly_date.dart';
import 'package:family_ledger/features/transactions/models/transaction_exceptions.dart';
import 'package:family_ledger/features/transactions/models/transaction_type_label.dart';
import 'package:family_ledger/features/transactions/providers/transactions_view_model.dart';
import 'package:family_ledger/models/category_model.dart';
import 'package:family_ledger/models/transaction_model.dart';
import 'package:family_ledger/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Material 3 bottom sheet for both adding a new transaction and editing
/// an existing one, for a single person.
class AddEditTransactionSheet extends ConsumerStatefulWidget {
  const AddEditTransactionSheet({
    super.key,
    required this.personId,
    this.initialTransaction,
  });

  final int personId;
  final TransactionModel? initialTransaction;

  /// Shows the sheet. Pass [initialTransaction] to edit; omit it to add.
  static Future<void> show(
    BuildContext context, {
    required int personId,
    TransactionModel? initialTransaction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => AddEditTransactionSheet(
        personId: personId,
        initialTransaction: initialTransaction,
      ),
    );
  }

  @override
  ConsumerState<AddEditTransactionSheet> createState() =>
      _AddEditTransactionSheetState();
}

class _AddEditTransactionSheetState
    extends ConsumerState<AddEditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _remarkController;
  final _remarkFocusNode = FocusNode();

  late TransactionType _type;
  late bool _isAdjustmentIncrease;
  int? _categoryId;
  late DateTime _date;
  bool _isSaving = false;
  String? _submitError;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.initialTransaction;

    _type = transaction?.transactionType ?? TransactionType.expensePaid;
    _isAdjustmentIncrease = (transaction?.amount ?? 0) >= 0;
    _amountController = TextEditingController(
      text: transaction == null ? '' : transaction.amount.abs().toString(),
    );
    _remarkController = TextEditingController(text: transaction?.remark ?? '');
    _categoryId = transaction?.categoryId;
    _date = transaction?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    _remarkFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final magnitude = double.tryParse(_amountController.text.trim()) ?? 0;
    final signedInput = _type == TransactionType.adjustment && !_isAdjustmentIncrease
        ? -magnitude
        : magnitude;

    final viewModel = ref.read(
      transactionsViewModelProvider(widget.personId).notifier,
    );

    try {
      if (_isEditing) {
        await viewModel.updateTransaction(
          original: widget.initialTransaction!,
          amount: signedInput,
          transactionType: _type,
          categoryId: _categoryId,
          remark: _remarkController.text,
          date: _date,
        );
      } else {
        await viewModel.addTransaction(
          amount: signedInput,
          transactionType: _type,
          categoryId: _categoryId,
          remark: _remarkController.text,
          date: _date,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } on InvalidTransactionAmountException catch (error) {
      setState(() => _submitError = error.message);
    } on RemarkTooLongException catch (error) {
      setState(() => _submitError = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  _isEditing ? 'Edit Transaction' : 'Add Transaction',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (_submitError != null) {
                      setState(() => _submitError = null);
                    }
                  },
                  validator: (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter an amount greater than zero';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _remarkFocusNode.requestFocus(),
                ),
                const SizedBox(height: 16),
                DropdownMenu<TransactionType>(
                  initialSelection: _type,
                  label: const Text('Transaction Type'),
                  width: double.infinity,
                  dropdownMenuEntries: [
                    for (final type in TransactionType.values)
                      DropdownMenuEntry(value: type, label: type.label),
                  ],
                  onSelected: (value) {
                    if (value == null) return;
                    setState(() => _type = value);
                  },
                ),
                if (_type == TransactionType.adjustment) ...[
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Increase'),
                        icon: Icon(Icons.add),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Decrease'),
                        icon: Icon(Icons.remove),
                      ),
                    ],
                    selected: {_isAdjustmentIncrease},
                    onSelectionChanged: (selection) {
                      setState(() => _isAdjustmentIncrease = selection.first);
                    },
                  ),
                ],
                const SizedBox(height: 16),
                categoriesAsync.when(
                  data: (categories) => _CategoryDropdown(
                    categories: categories,
                    selectedCategoryId: _categoryId,
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _remarkController,
                  focusNode: _remarkFocusNode,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: maxTransactionRemarkLength,
                  decoration: const InputDecoration(
                    labelText: 'Remark (optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) {
                    if (_submitError != null) {
                      setState(() => _submitError = null);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Text(FriendlyDate.format(_date)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule_outlined, size: 18),
                        label: Text(TimeOfDay.fromDateTime(_date).format(context)),
                      ),
                    ),
                  ],
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _submitError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<int?>(
      initialSelection: selectedCategoryId,
      label: const Text('Category (optional)'),
      width: double.infinity,
      dropdownMenuEntries: [
        const DropdownMenuEntry(value: null, label: 'None'),
        for (final category in categories)
          if (category.id != null)
            DropdownMenuEntry(value: category.id, label: category.name),
      ],
      onSelected: onChanged,
    );
  }
}
