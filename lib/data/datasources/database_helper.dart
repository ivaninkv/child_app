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

    return await openDatabase(path, version: 1, onCreate: _createDB);
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
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE photos (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        image_path TEXT NOT NULL,
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
    return result.map((map) => Event.fromMap(map)).toList();
  }

  Future<Event?> getEvent(String id) async {
    final db = await database;
    final result = await db.query('events', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Event.fromMap(result.first);
  }

  Future<int> updateEvent(Event event) async {
    final db = await database;
    return db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
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
    return result.map((map) => Parameter.fromMap(map)).toList();
  }

  Future<Parameter?> getParameter(String id) async {
    final db = await database;
    final result = await db.query(
      'parameters',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Parameter.fromMap(result.first);
  }

  Future<int> updateParameter(Parameter parameter) async {
    final db = await database;
    return db.update(
      'parameters',
      parameter.toMap(),
      where: 'id = ?',
      whereArgs: [parameter.id],
    );
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

  // Get all timeline items for a child (events, photos, parameters merged and sorted)
  Future<List<TimelineItem>> getTimelineForChild(String childId) async {
    final events = await getEventsForChild(childId);
    final photos = await getPhotosForChild(childId);
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

    for (final photo in photos) {
      timeline.add(
        TimelineItem(
          id: photo.id,
          type: TimelineItemType.photo,
          date: photo.date,
          childId: childId,
          photo: photo,
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
