import 'dart:io';

import 'package:drift/native.dart';
import 'package:family_ledger/core/database/app_database.dart';

/// Creates an in-memory [AppDatabase] with schema initialized (onCreate runs).
Future<AppDatabase> createTestDatabase() async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  await database.customSelect('SELECT 1').get();
  return database;
}

/// Creates a file-backed [AppDatabase] for persistence tests.
Future<AppDatabase> createTestDatabaseOnFile(String path) async {
  final database = AppDatabase.forTesting(NativeDatabase(File(path)));
  await database.customSelect('SELECT 1').get();
  return database;
}
