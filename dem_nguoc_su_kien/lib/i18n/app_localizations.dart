import 'package:flutter/material.dart';

class AppLoc {
  final Locale locale;
  AppLoc(this.locale);

  static AppLoc of(BuildContext context) =>
      Localizations.of<AppLoc>(context, AppLoc)!;

  static const LocalizationsDelegate<AppLoc> delegate = _AppLocDelegate();

  static const _values = {
    'vi': {
      // ===== CŨ =====
      'language': 'Ngôn ngữ',
      'notLoggedIn': 'Bạn chưa đăng nhập.',
      'titleEventList': 'Danh sách sự kiện',
      'noEvents': 'Chưa có sự kiện nào',
      'arrived': 'ĐÃ ĐẾN HẸN',
      'edit': 'Sửa',
      'delete': 'Xoá',
      'deleteEvent': 'Xoá sự kiện',
      'cancel': 'Hủy',
      'deletedToast': '🗑️ Đã xoá sự kiện',
      'addEvent': 'Thêm sự kiện',
      'eventTitle': 'Tiêu đề sự kiện',
      'eventHint': 'Nhập sự kiện của bạn',
      'eventTime': 'Thời điểm sự kiện',
      'notChosen': 'Chưa chọn',
      'remindAt': 'Nhắc lúc (tùy chọn)',
      'noReminder': 'Không nhắc',
      'pickColor': 'Chọn màu thẻ',
      'note': 'Ghi chú (tùy chọn)',
      'saveEvent': 'Lưu sự kiện',
      'editEvent': 'Sửa sự kiện',
      'saveChanges': 'Lưu thay đổi',
      'pickDate': 'Chọn ngày',
      'pickTime': 'Chọn giờ',
      'done': 'Xong',
      'soon': 'Sắp đến: ',
      'pleasePickTime': 'Chọn thời điểm',

      // ===== MỚI: Onboarding =====
      'welcome': 'Chào mừng!',
      'chooseLanguage': 'Chọn ngôn ngữ',
      'onbTitle1': 'Đếm ngược sự kiện',
      'onbDesc1': 'Tạo sự kiện quan trọng và theo dõi thời gian đến hẹn.',
      'onbTitle2': 'Thông báo thông minh',
      'onbDesc2': 'Bật thông báo để được nhắc khi sắp đến hạn.',
      'onbTitle3': 'Ảnh & avatar',
      'onbDesc3': 'Cho phép camera/thư viện để chọn và cắt avatar.',
      'enableNotifications': 'Bật thông báo',
      'enableMedia': 'Cho phép camera/thư viện',
      'skip': 'Bỏ qua',
      'next': 'Tiếp',
      'getStarted': 'Bắt đầu',
      'later': 'Để sau',
      'granted': 'Đã cấp quyền',
      'denied': 'Đã từ chối',
    },
    'en': {
      // ===== OLD =====
      'language': 'Language',
      'notLoggedIn': 'You are not logged in.',
      'titleEventList': 'Event list',
      'noEvents': 'No events yet',
      'arrived': 'ARRIVED',
      'edit': 'Edit',
      'delete': 'Delete',
      'deleteEvent': 'Delete event',
      'cancel': 'Cancel',
      'deletedToast': '🗑️ Event deleted',
      'addEvent': 'Add event',
      'eventTitle': 'Event title',
      'eventHint': 'Enter your event',
      'eventTime': 'Event time',
      'notChosen': 'Not chosen',
      'remindAt': 'Remind at (optional)',
      'noReminder': 'No reminder',
      'pickColor': 'Pick card color',
      'note': 'Note (optional)',
      'saveEvent': 'Save event',
      'editEvent': 'Edit event',
      'saveChanges': 'Save changes',
      'pickDate': 'Pick date',
      'pickTime': 'Pick time',
      'done': 'Done',
      'soon': 'Upcoming: ',
      'pleasePickTime': 'Please pick event time',

      // ===== NEW: Onboarding =====
      'welcome': 'Welcome!',
      'chooseLanguage': 'Choose language',
      'onbTitle1': 'Event countdown',
      'onbDesc1': 'Create important events and track the time to them.',
      'onbTitle2': 'Smart notifications',
      'onbDesc2': 'Enable notifications to be reminded before due.',
      'onbTitle3': 'Photos & avatar',
      'onbDesc3': 'Allow camera/gallery to pick and crop your avatar.',
      'enableNotifications': 'Enable notifications',
      'enableMedia': 'Allow camera/gallery',
      'skip': 'Skip',
      'next': 'Next',
      'getStarted': 'Get started',
      'later': 'Later',
      'granted': 'Granted',
      'denied': 'Denied',
    },
  };

  String _t(String k) => (_values[locale.languageCode] ?? _values['en']!)[k] ?? k;

  // ===== Getters cũ =====
  String get language => _t('language');
  String get notLoggedIn => _t('notLoggedIn');
  String get titleEventList => _t('titleEventList');
  String get noEvents => _t('noEvents');
  String get arrived => _t('arrived');
  String get edit => _t('edit');
  String get delete => _t('delete');
  String get deleteEvent => _t('deleteEvent');
  String get cancel => _t('cancel');
  String get deletedToast => _t('deletedToast');
  String get addEvent => _t('addEvent');
  String get eventTitle => _t('eventTitle');
  String get eventHint => _t('eventHint');
  String get eventTime => _t('eventTime');
  String get notChosen => _t('notChosen');
  String get remindAt => _t('remindAt');
  String get noReminder => _t('noReminder');
  String get pickColor => _t('pickColor');
  String get note => _t('note');
  String get saveEvent => _t('saveEvent');
  String get editEvent => _t('editEvent');
  String get saveChanges => _t('saveChanges');
  String get pickDate => _t('pickDate');
  String get pickTime => _t('pickTime');
  String get done => _t('done');
  String get soon => _t('soon');
  String get pleasePickTime => _t('pleasePickTime');

  // ===== Getters mới =====
  String get welcome => _t('welcome');
  String get chooseLanguage => _t('chooseLanguage');
  String get onbTitle1 => _t('onbTitle1');
  String get onbDesc1 => _t('onbDesc1');
  String get onbTitle2 => _t('onbTitle2');
  String get onbDesc2 => _t('onbDesc2');
  String get onbTitle3 => _t('onbTitle3');
  String get onbDesc3 => _t('onbDesc3');
  String get enableNotifications => _t('enableNotifications');
  String get enableMedia => _t('enableMedia');
  String get skip => _t('skip');
  String get next => _t('next');
  String get getStarted => _t('getStarted');
  String get later => _t('later');
  String get granted => _t('granted');
  String get denied => _t('denied');

  String deleteConfirm(String title) {
    if (locale.languageCode == 'vi') {
      return 'Bạn có chắc muốn xoá "$title" không?';
    } else {
      return 'Are you sure to delete "$title"?';
    }
  }
}

class _AppLocDelegate extends LocalizationsDelegate<AppLoc> {
  const _AppLocDelegate();

  @override
  bool isSupported(Locale locale) => ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<AppLoc> load(Locale locale) async => AppLoc(locale);

  @override
  bool shouldReload(_AppLocDelegate old) => false;
}
