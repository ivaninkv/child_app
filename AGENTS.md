# AGENTS.md — Руководство для агентов

## Общие сведения

**Child App** — Flutter-приложение для записи моментов жизни ребёнка (фото, события, параметры роста). Архитектура: Clean Architecture + BLoC.

---

## Команды

### Установка зависимостей
```bash
flutter pub get
```

### Сборка APK (release)
```bash
flutter build apk --release
```
APK появится в `build/app/outputs/flutter-apk/`

### Сборка APK (debug)
```bash
flutter build apk --debug
```

### Анализ кода (линтинг)
```bash
flutter analyze
```

### Запуск всех тестов
```bash
flutter test
```

### Запуск одного теста
```bash
flutter test test/widget_test.dart
flutter test --name "test_name" .
```

### Форматирование кода
```bash
dart format .
```

---

## Структура проекта (полная)

```
lib/
├── main.dart                              # Точка входа, инициализация BLoC-провайдеров
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart             # Константы приложения
│   ├── theme/
│   │   └── app_theme.dart                 # Темы: lightTheme, darkTheme
│   └── utils/
│       ├── date_utils.dart                # Форматирование дат
│       └── notification_service.dart       # Уведомления (flutter_local_notifications)
│
├── data/
│   ├── datasources/
│   │   └── database_helper.dart           # SQLite: DatabaseHelper.instance, CRUD операции
│   └── models/
│       ├── models.dart                     # barrel file: export всех моделей
│       ├── child.dart                      # Профиль ребёнка: id, name, birthDate, gender, avatarPath
│       ├── event.dart                      # Событие: id, childId, title, description, date, category
│       ├── photo.dart                      # Фото: id, childId, imagePath, date, tags (List<String>)
│       ├── parameter.dart                  # Параметры: id, childId, date, height, weight, shoeSize
│       └── reminder_settings.dart         # Настройки уведомлений
│
└── presentation/
    ├── bloc/                               # BLoC-блоки (события → состояния)
    │   ├── app/
    │   │   └── app_bloc.dart               # Глобальное состояние: themeMode, selectedChild, children
    │   ├── children/
    │   │   └── children_bloc.dart          # Управление профилями детей (CRUD)
    │   ├── events/
    │   │   └── events_bloc.dart            # Текстовые события (CRUD)
    │   ├── photos/
    │   │   └── photos_bloc.dart            # Фотогалерея (CRUD, теги)
    │   ├── parameters/
    │   │   └── parameters_bloc.dart         # Параметры роста (CRUD)
    │   ├── reminders/
    │   │   └── reminders_bloc.dart          # Настройки уведомлений
    │   └── timeline/
    │       └── timeline_bloc.dart           # Объединённая лента (события + фото + параметры)
    │
    ├── screens/                            # Экраны (Route → Widget)
    │   ├── home_screen.dart                 # Главный экран: BottomNavigationBar + TimelineBloc
    │   ├── children_screen.dart             # Список детей
    │   ├── child_form_screen.dart           # Добавить/редактировать ребёнка
    │   ├── event_form_screen.dart           # Добавить/редактировать событие
    │   ├── photo_gallery_screen.dart         # Галерея фото с фильтрацией по тегам
    │   ├── photo_form_screen.dart           # Добавить фото (камера/галерея, теги)
    │   ├── photo_viewer_screen.dart         # Просмотр фото (свайп, мультивыбор)
    │   ├── photo_fullscreen_screen.dart     # Полноэкранный просмотр (zoom)
    │   ├── growth_screen.dart               # Графики роста/веса (fl_chart)
    │   ├── parameter_form_screen.dart       # Добавить замер
    │   ├── timeline_detail_screen.dart      # Детали элемента ленты
    │   └── settings_screen.dart             # Тема, уведомления, очистка
    │
    ├── widgets/
    │   └── timeline_card.dart               # Карточка элемента ленты
    │
    └── router/
        └── app_router.dart                  # GoRouter: AppRouter.router, маршруты
```

---

## Как добавить новую фичу

### 1. Новая модель данных
- Добавить в `lib/data/models/` → `new_model.dart`
- Наследовать от `Equatable`, добавить `copyWith`, `toMap`, `fromMap`
- Экспортировать в `lib/data/models/models.dart`
- Добавить таблицу в `lib/data/datasources/database_helper.dart`

### 2. Новый BLoC
- Создать `lib/presentation/bloc/new_feature/new_feature_bloc.dart`
- Events: `LoadNewFeature`, `AddNewFeature`, `UpdateNewFeature`, `DeleteNewFeature`
- State: `NewFeatureState` с полями `List<NewFeature> items, bool isLoading, String? error`
- Зарегистрировать провайдер в `lib/main.dart`

### 3. Новый экран
- Создать в `lib/presentation/screens/`
- Добавить маршрут в `lib/presentation/router/app_router.dart`
- Добавить навигацию в BottomNavigationBar (`home_screen.dart`)

### 4. Изменение UI
- Timeline: `timeline_bloc.dart` (объединение данных)
- Карточки: `timeline_card.dart`
- Отдельный экран: соответствующий screen в `presentation/screens/`

---

## Стиль кода

### Импорты (группы через пустую строку)
1. Dart SDK → 2. Внешние пакеты → 3. Внутренние пакеты → 4. Относительные

### Именование
- Файлы: snake_case (`child_form_screen.dart`)
- Классы: PascalCase (`ChildFormScreen`)
- Константы: camelCase + kPrefix (`kDefaultPageSize = 20`)
- Enum: PascalCase, значения PascalCase (`enum Gender { male, female }`)
- BLoC: `{Name}Bloc` (`EventsBloc`)
- События: `{Name}{Action}Event` (`AppInitialize`)
- Состояния: `{Name}State` (`AppState`)

### Типы
- Явные типы для параметров и возвращаемых значений
- Nullable: `Type?`
- Используй `const` где возможно
- Избегай `dynamic`

### Форматирование
- Отступ: 2 пробела
- Длина строки: ≤80-100 символов
- Финальные запятые в коллекциях

### Модели
Наследуйся от `Equatable`, используй `copyWith`:
```dart
class Child extends Equatable {
  final String id;
  final String name;
  const Child({required this.id, required this.name});
  @override List<Object?> get props => [id, name];
  Child copyWith({String? name}) => Child(id: id, name: name ?? this.name);
  Map<String, dynamic> toMap() => {'id': id, 'name': name};
  factory Child.fromMap(Map<String, dynamic> map) => Child(id: map['id'], name: map['name']);
}
```

### BLoC паттерн
```dart
abstract class Event extends Equatable { }
class LoadEvent extends Event { }
class State {
  final List<Item> items;
  final bool isLoading;
  const State({this.items = const [], this.isLoading = false});
  State copyWith({List<Item>? items, bool? isLoading}) => State(items: items ?? this.items, isLoading: isLoading ?? this.isLoading);
}
class Bloc extends Bloc<Event, State> {
  Bloc() : super(const State()) { on<LoadEvent>(_onLoad); }
  Future<void> _onLoad(LoadEvent event, Emitter<State> emit) async { ... }
}
```

### Обработка ошибок
```dart
Future<void> _onLoad(LoadEvent event, Emitter<State> emit) async {
  emit(state.copyWith(isLoading: true));
  try {
    final data = await _repo.getData();
    emit(state.copyWith(data: data, isLoading: false));
  } catch (e) {
    emit(state.copyWith(error: e.toString(), isLoading: false));
  }
}
```

---

## Работа с БД

```dart
final db = DatabaseHelper.instance;
await db.insertChild(child);
final children = await db.getAllChildren();
await db.updateChild(child);
await db.deleteChild(childId);
```

---

## Зависимости

- `sqflite` — SQLite
- `flutter_bloc` — состояние
- `go_router` — навигация
- `equatable` — сравнение объектов
- `image_picker` — фото
- `fl_chart` — графики
- `flutter_local_notifications` — уведомления
- `intl` — даты

---

## Коммиты

Формат: `тип: описание` (на русском или английском)

Типы:
- `feat:` — новая функциональность
- `fix:` — исправление бага
- `refactor:` — рефакторинг
- `Add:` — добавление файлов/крупных фич
- `Merge:` — слияние веток

Примеры: `fix: отображение фото в режиме просмотра`, `feat: добавить график роста`
