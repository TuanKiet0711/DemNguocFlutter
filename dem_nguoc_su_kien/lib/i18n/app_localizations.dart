import 'package:flutter/material.dart';

class AppLoc {
  final Locale locale;
  AppLoc(this.locale);

  static AppLoc of(BuildContext context) =>
      Localizations.of<AppLoc>(context, AppLoc)!;

  static const LocalizationsDelegate<AppLoc> delegate = _AppLocDelegate();

  static const _values = {
    'vi': {
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
    },
    'en': {
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
    },
  };

  String _t(String k) => (_values[locale.languageCode] ?? _values['en']!)[k] ?? k;

  // getters
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
