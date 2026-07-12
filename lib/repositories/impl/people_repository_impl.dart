import 'package:drift/drift.dart';
import 'package:family_ledger/core/constants/enums.dart';
import 'package:family_ledger/core/database/app_database.dart';
import 'package:family_ledger/core/database/mappers/entity_mappers.dart';
import 'package:family_ledger/models/person_model.dart';
import 'package:family_ledger/repositories/people_repository.dart';

/// Drift-backed implementation of [PeopleRepository].
class PeopleRepositoryImpl implements PeopleRepository {
  PeopleRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<PersonModel>> getAll({PersonStatus? status}) async {
    final query = _database.select(_database.people);

    if (status != null) {
      query.where((person) => person.status.equalsValue(status));
    }

    query.orderBy([(person) => OrderingTerm.asc(person.name)]);

    final entities = await query.get();
    return entities.map(EntityMappers.toPerson).toList();
  }

  @override
  Future<PersonModel?> getById(int id) async {
    final entity = await (_database.select(
      _database.people,
    )..where((person) => person.id.equals(id))).getSingleOrNull();

    return entity == null ? null : EntityMappers.toPerson(entity);
  }

  @override
  Future<int> insert(PersonModel person) {
    return _database
        .into(_database.people)
        .insert(EntityMappers.toPersonCompanion(person));
  }

  @override
  Future<bool> update(PersonModel person) async {
    if (person.id == null) return false;

    final rowsAffected =
        await (_database.update(_database.people)
              ..where((row) => row.id.equals(person.id!)))
            .write(EntityMappers.toPersonCompanion(person));

    return rowsAffected > 0;
  }

  @override
  Future<bool> archive(int id) async {
    final rowsAffected =
        await (_database.update(
          _database.people,
        )..where((person) => person.id.equals(id))).write(
          PeopleCompanion(
            status: const Value(PersonStatus.archived),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return rowsAffected > 0;
  }

  @override
  Future<bool> delete(int id) async {
    final rowsAffected = await (_database.delete(
      _database.people,
    )..where((person) => person.id.equals(id))).go();

    return rowsAffected > 0;
  }

  @override
  Future<void> deleteAll() async {
    await _database.delete(_database.people).go();
  }
}
