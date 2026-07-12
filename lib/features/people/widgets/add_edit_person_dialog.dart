import 'dart:math';

import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/features/people/models/people_exceptions.dart';
import 'package:family_ledger/features/people/providers/people_view_model.dart';
import 'package:family_ledger/features/people/widgets/person_avatar.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Material 3 dialog for both adding a new person and editing an existing
/// one.
///
/// Add mode auto-generates the avatar with no user control over it
/// (matching "users do not choose avatar colors manually"). Edit mode adds
/// a "regenerate" action next to the avatar preview, since the person's
/// color is one of the fields this mode allows changing.
class AddEditPersonDialog extends ConsumerStatefulWidget {
  const AddEditPersonDialog({super.key, this.initialPerson});

  final PersonModel? initialPerson;

  /// Shows the dialog. Pass [initialPerson] to edit; omit it to add.
  static Future<void> show(BuildContext context, {PersonModel? initialPerson}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AddEditPersonDialog(initialPerson: initialPerson),
    );
  }

  @override
  ConsumerState<AddEditPersonDialog> createState() =>
      _AddEditPersonDialogState();
}

class _AddEditPersonDialogState extends ConsumerState<AddEditPersonDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late PersonType _type;
  late int _avatarSeedPreview;
  bool _isSaving = false;
  String? _submitError;

  bool get _isEditing => widget.initialPerson != null;

  @override
  void initState() {
    super.initState();
    final person = widget.initialPerson;
    _nameController = TextEditingController(text: person?.name ?? '');
    _type = person?.type ?? PersonType.temporary;
    _avatarSeedPreview = person?.effectiveAvatarSeed ?? _newRandomSeed();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int _newRandomSeed() => Random().nextInt(1 << 31);

  void _regeneratePreview() {
    setState(() {
      _avatarSeedPreview = _newRandomSeed();
      _submitError = null;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final viewModel = ref.read(peopleViewModelProvider.notifier);

    try {
      if (_isEditing) {
        await viewModel.updatePerson(
          person: widget.initialPerson!,
          name: _nameController.text,
          type: _type,
          avatarSeed: _avatarSeedPreview,
        );
      } else {
        await viewModel.addPerson(
          name: _nameController.text,
          type: _type,
          avatarSeed: _avatarSeedPreview,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } on EmptyPersonNameException catch (error) {
      setState(() => _submitError = error.message);
    } on DuplicatePersonNameException catch (error) {
      setState(() => _submitError = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(_isEditing ? 'Edit Person' : 'Add Person'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    SeedAvatarPreview(
                      seed: _avatarSeedPreview,
                      name: _nameController.text,
                      radius: 34,
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextButton.icon(
                        onPressed: _regeneratePreview,
                        icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                        label: const Text('New color'),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Avatar generated automatically',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_submitError != null) setState(() => _submitError = null);
                  if (!_isEditing) setState(() {}); // refresh avatar initial
                },
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Person Type', style: theme.textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              SegmentedButton<PersonType>(
                segments: const [
                  ButtonSegment(
                    value: PersonType.permanent,
                    label: Text('Permanent'),
                    icon: Icon(Icons.home_outlined),
                  ),
                  ButtonSegment(
                    value: PersonType.temporary,
                    label: Text('Temporary'),
                    icon: Icon(Icons.person_outline),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() => _type = selection.first);
                },
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
