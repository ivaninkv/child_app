import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('child_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE photos ADD COLUMN thumbnail_path TEXT');
    }
    if (oldVersion < 3) {
      // Проверяем, существует ли колонка thumbnail_path
      final result = await db.rawQuery("PRAGMA table_info(photos)");
      final hasThumbnailPath = result.any(
        (col) => col['name'] == 'thumbnail_path',
      );
      if (!hasThumbnailPath) {
        await db.execute('ALTER TABLE photos ADD COLUMN thumbnail_path TEXT');
      }
    }
    if (oldVersion < 4) {
      // Добавляем таблицу event_photos для связи событий и фотографий
      await db.execute('''
        CREATE TABLE event_photos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id TEXT NOT NULL,
          photo_id TEXT NOT NULL,
          FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
          FOREIGN KEY (photo_id) REFERENCES photos (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_event_photos_event_id ON event_photos (event_id)',
      );
      await db.execute(
        'CREATE INDEX idx_event_photos_photo_id ON event_photos (photo_id)',
      );

      // Добавляем колонку photo_ids в таблицу events для обратной совместимости
      final result = await db.rawQuery("PRAGMA table_info(events)");
      final hasPhotoIds = result.any((col) => col['name'] == 'photo_ids');
      if (!hasPhotoIds) {
        await db.execute('ALTER TABLE events ADD COLUMN photo_ids TEXT');
      }
    }
    if (oldVersion < 5) {
      // Добавляем колонку photo_ids в таблицу parameters
      final result = await db.rawQuery("PRAGMA table_info(parameters)");
      final hasPhotoIds = result.any((col) => col['name'] == 'photo_ids');
      if (!hasPhotoIds) {
        await db.execute('ALTER TABLE parameters ADD COLUMN photo_ids TEXT');
      }

      // Добавляем таблицу parameter_photos для связи замеров и фотографий
      await db.execute('''
        CREATE TABLE parameter_photos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          parameter_id TEXT NOT NULL,
          photo_id TEXT NOT NULL,
          FOREIGN KEY (parameter_id) REFERENCES parameters (id) ON DELETE CASCADE,
          FOREIGN KEY (photo_id) REFERENCES photos (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_parameter_photos_parameter_id ON parameter_photos (parameter_id)',
      );
      await db.execute(
        'CREATE INDEX idx_parameter_photos_photo_id ON parameter_photos (photo_id)',
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE children (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        birth_date INTEGER NOT NULL,
        gender TEXT NOT NULL,
        avatar_path TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        date INTEGER NOT NULL,
        category TEXT,
        created_at INTEGER NOT NULL,
        photo_ids TEXT,
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        image_path TEXT NOT NULL,
        thumbnail_path TEXT,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE photo_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        photo_id TEXT NOT NULL,
        tag TEXT NOT NULL,
        FOREIGN KEY (photo_id) REFERENCES photos (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE parameters (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        date INTEGER NOT NULL,
        height REAL,
        weight REAL,
        shoe_size REAL,
        created_at INTEGER NOT NULL,
        photo_ids TEXT,
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reminder_settings (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL UNIQUE,
        interval TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        last_notified INTEGER,
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_events_child_id ON events (child_id)');
    await db.execute('CREATE INDEX idx_events_date ON events (date)');
    await db.execute('CREATE INDEX idx_photos_child_id ON photos (child_id)');
    await db.execute('CREATE INDEX idx_photos_date ON photos (date)');
    await db.execute(
      'CREATE INDEX idx_parameters_child_id ON parameters (child_id)',
    );
    await db.execute('CREATE INDEX idx_parameters_date ON parameters (date)');
    await db.execute(
      'CREATE INDEX idx_photo_tags_photo_id ON photo_tags (photo_id)',
    );

    // Create event_photos table
    await db.execute('''
      CREATE TABLE event_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id TEXT NOT NULL,
        photo_id TEXT NOT NULL,
        FOREIGN KEY (event_id) REFERENCES events (id) ON DELETE CASCADE,
        FOREIGN KEY (photo_id) REFERENCES photos (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_event_photos_event_id ON event_photos (event_id)',
    );
    await db.execute(
      'CREATE INDEX idx_event_photos_photo_id ON event_photos (photo_id)',
    );

    // Create parameter_photos table
    await db.execute('''
      CREATE TABLE parameter_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parameter_id TEXT NOT NULL,
        photo_id TEXT NOT NULL,
        FOREIGN KEY (parameter_id) REFERENCES parameters (id) ON DELETE CASCADE,
        FOREIGN KEY (photo_id) REFERENCES photos (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_parameter_photos_parameter_id ON parameter_photos (parameter_id)',
    );
    await db.execute(
      'CREATE INDEX idx_parameter_photos_photo_id ON parameter_photos (photo_id)',
    );
  }

  // Children CRUD
  Future<String> insertChild(Child child) async {
    final db = await database;
    await db.insert('children', child.toMap());
    return child.id;
  }

  Future<List<Child>> getAllChildren() async {
    final db = await database;
    final result = await db.query('children', orderBy: 'created_at ASC');
    return result.map((map) => Child.fromMap(map)).toList();
  }

  Future<Child?> getChild(String id) async {
    final db = await database;
    final result = await db.query('children', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Child.fromMap(result.first);
  }

  Future<int> updateChild(Child child) async {
    final db = await database;
    return db.update(
      'children',
      child.toMap(),
      where: 'id = ?',
      whereArgs: [child.id],
    );
  }

  Future<int> deleteChild(String id) async {
    final db = await database;
    return db.delete('children', where: 'id = ?', whereArgs: [id]);
  }

  // Events CRUD
  Future<String> insertEvent(Event event) async {
    final db = await database;
    await db.insert('events', event.toMap());

    // Insert event-photo associations
    for (final photoId in event.photoIds) {
      await db.insert('event_photos', {
        'event_id': event.id,
        'photo_id': photoId,
      });
    }

    return event.id;
  }

  Future<List<Event>> getEventsForChild(String childId) async {
    final db = await database;
    final result = await db.query(
      'events',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'date DESC',
    );

    final events = <Event>[];
    for (final eventMap in result) {
      // Get photo IDs for this event
      final photoIdsResult = await db.query(
        'event_photos',
        columns: ['photo_id'],
        where: 'event_id = ?',
        whereArgs: [eventMap['id']],
      );
      final photoIds = photoIdsResult
          .map((r) => r['photo_id'] as String)
          .toList();

      // Create event with photo IDs - create a new map to avoid read-only issues
      final updatedEventMap = Map<String, dynamic>.from(eventMap);
      updatedEventMap['photo_ids'] = photoIds.join(',');
      events.add(Event.fromMap(updatedEventMap));
    }

    return events;
  }

  Future<Event?> getEvent(String id) async {
    final db = await database;
    final result = await db.query('events', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;

    // Get photo IDs for this event
    final photoIdsResult = await db.query(
      'event_photos',
      columns: ['photo_id'],
      where: 'event_id = ?',
      whereArgs: [id],
    );
    final photoIds = photoIdsResult
        .map((r) => r['photo_id'] as String)
        .toList();

    // Create event with photo IDs - create a new map to avoid read-only issues
    final eventMap = Map<String, dynamic>.from(result.first);
    eventMap['photo_ids'] = photoIds.join(',');

    return Event.fromMap(eventMap);
  }

  Future<int> updateEvent(Event event) async {
    final db = await database;
    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );

    // Update event-photo associations
    await db.delete(
      'event_photos',
      where: 'event_id = ?',
      whereArgs: [event.id],
    );
    for (final photoId in event.photoIds) {
      await db.insert('event_photos', {
        'event_id': event.id,
        'photo_id': photoId,
      });
    }

    return 1;
  }

  Future<int> deleteEvent(String id) async {
    final db = await database;
    return db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // Photos CRUD
  Future<String> insertPhoto(Photo photo) async {
    final db = await database;
    await db.insert('photos', photo.toMap());

    for (final tag in photo.tags) {
      await db.insert('photo_tags', {'photo_id': photo.id, 'tag': tag});
    }

    return photo.id;
  }

  Future<List<Photo>> getPhotosForChild(String childId) async {
    final db = await database;
    final photosResult = await db.query(
      'photos',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'date DESC',
    );

    final photos = <Photo>[];
    for (final photoMap in photosResult) {
      final tagsResult = await db.query(
        'photo_tags',
        columns: ['tag'],
        where: 'photo_id = ?',
        whereArgs: [photoMap['id']],
      );
      final tags = tagsResult.map((t) => t['tag'] as String).toList();
      photos.add(Photo.fromMap(photoMap, tags: tags));
    }

    return photos;
  }

  Future<Photo?> getPhoto(String id) async {
    final db = await database;
    final result = await db.query('photos', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;

    final tagsResult = await db.query(
      'photo_tags',
      columns: ['tag'],
      where: 'photo_id = ?',
      whereArgs: [id],
    );
    final tags = tagsResult.map((t) => t['tag'] as String).toList();

    return Photo.fromMap(result.first, tags: tags);
  }

  Future<int> updatePhoto(Photo photo) async {
    final db = await database;
    await db.update(
      'photos',
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );

    await db.delete('photo_tags', where: 'photo_id = ?', whereArgs: [photo.id]);
    for (final tag in photo.tags) {
      await db.insert('photo_tags', {'photo_id': photo.id, 'tag': tag});
    }

    return 1;
  }

  Future<int> deletePhoto(String id) async {
    final db = await database;
    return db.delete('photos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getAllTags() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT tag FROM photo_tags ORDER BY tag',
    );
    return result.map((r) => r['tag'] as String).toList();
  }

  // Parameters CRUD
  Future<String> insertParameter(Parameter parameter) async {
    final db = await database;
    await db.insert('parameters', parameter.toMap());

    // Insert parameter-photo associations
    for (final photoId in parameter.photoIds) {
      await db.insert('parameter_photos', {
        'parameter_id': parameter.id,
        'photo_id': photoId,
      });
    }

    return parameter.id;
  }

  Future<List<Parameter>> getParametersForChild(String childId) async {
    final db = await database;
    final result = await db.query(
      'parameters',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'date DESC',
    );

    final parameters = <Parameter>[];
    for (final paramMap in result) {
      // Get photo IDs for this parameter
      final photoIdsResult = await db.query(
        'parameter_photos',
        columns: ['photo_id'],
        where: 'parameter_id = ?',
        whereArgs: [paramMap['id']],
      );
      final photoIds = photoIdsResult
          .map((r) => r['photo_id'] as String)
          .toList();

      // Create parameter with photo IDs
      final updatedParamMap = Map<String, dynamic>.from(paramMap);
      updatedParamMap['photo_ids'] = photoIds.join(',');
      parameters.add(Parameter.fromMap(updatedParamMap));
    }

    return parameters;
  }

  Future<Parameter?> getParameter(String id) async {
    final db = await database;
    final result = await db.query(
      'parameters',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;

    // Get photo IDs for this parameter
    final photoIdsResult = await db.query(
      'parameter_photos',
      columns: ['photo_id'],
      where: 'parameter_id = ?',
      whereArgs: [id],
    );
    final photoIds = photoIdsResult
        .map((r) => r['photo_id'] as String)
        .toList();

    // Create parameter with photo IDs
    final paramMap = Map<String, dynamic>.from(result.first);
    paramMap['photo_ids'] = photoIds.join(',');

    return Parameter.fromMap(paramMap);
  }

  Future<int> updateParameter(Parameter parameter) async {
    final db = await database;
    await db.update(
      'parameters',
      parameter.toMap(),
      where: 'id = ?',
      whereArgs: [parameter.id],
    );

    // Update parameter-photo associations
    await db.delete(
      'parameter_photos',
      where: 'parameter_id = ?',
      whereArgs: [parameter.id],
    );
    for (final photoId in parameter.photoIds) {
      await db.insert('parameter_photos', {
        'parameter_id': parameter.id,
        'photo_id': photoId,
      });
    }

    return 1;
  }

  Future<int> deleteParameter(String id) async {
    final db = await database;
    return db.delete('parameters', where: 'id = ?', whereArgs: [id]);
  }

  // Reminder Settings CRUD
  Future<String> insertReminderSettings(ReminderSettings settings) async {
    final db = await database;
    await db.insert('reminder_settings', settings.toMap());
    return settings.id;
  }

  Future<ReminderSettings?> getReminderSettingsForChild(String childId) async {
    final db = await database;
    final result = await db.query(
      'reminder_settings',
      where: 'child_id = ?',
      whereArgs: [childId],
    );
    if (result.isEmpty) return null;
    return ReminderSettings.fromMap(result.first);
  }

  Future<int> updateReminderSettings(ReminderSettings settings) async {
    final db = await database;
    return db.update(
      'reminder_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  Future<int> deleteReminderSettings(String id) async {
    final db = await database;
    return db.delete('reminder_settings', where: 'id = ?', whereArgs: [id]);
  }

  // Get all timeline items for a child (events and parameters only, photos excluded)
  Future<List<TimelineItem>> getTimelineForChild(String childId) async {
    final events = await getEventsForChild(childId);
    final parameters = await getParametersForChild(childId);

    final timeline = <TimelineItem>[];

    for (final event in events) {
      timeline.add(
        TimelineItem(
          id: event.id,
          type: TimelineItemType.event,
          date: event.date,
          childId: childId,
          event: event,
        ),
      );
    }

    for (final param in parameters) {
      timeline.add(
        TimelineItem(
          id: param.id,
          type: TimelineItemType.parameter,
          date: param.date,
          childId: childId,
          parameter: param,
        ),
      );
    }

    timeline.sort((a, b) => b.date.compareTo(a.date));
    return timeline;
  }
}

enum TimelineItemType { event, photo, parameter }

class TimelineItem {
  final String id;
  final TimelineItemType type;
  final DateTime date;
  final String childId;
  final Event? event;
  final Photo? photo;
  final Parameter? parameter;

  TimelineItem({
    required this.id,
    required this.type,
    required this.date,
    required this.childId,
    this.event,
    this.photo,
    this.parameter,
  });
}
