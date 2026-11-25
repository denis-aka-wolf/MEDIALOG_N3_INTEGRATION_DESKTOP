import 'dart:convert';
import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

// Материал-библиотека Flutter остаётся целевой для текущей версии приложения.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

void main() => runApp(const MedialogN3App());

const _navItems = <_NavItem>[
  _NavItem('Обзор', Icons.space_dashboard_outlined),
  _NavItem('Предварительный контроль', Icons.fact_check_outlined),
  _NavItem('Очередь СЭМД', Icons.outbox_outlined),
  _NavItem('Архив документов', Icons.folder_open_outlined),
  _NavItem('ИЭМК пациентов', Icons.medical_information_outlined),
  _NavItem('Журнал действий', Icons.receipt_long_outlined),
  _NavItem('Настройки', Icons.settings_outlined),
];

class MedialogN3App extends StatelessWidget {
  const MedialogN3App({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2878B8);
    return MaterialApp(
      title: 'Medialog N3 Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.light,
          surface: const Color(0xFFF5F7FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE6EBF1)),
          ),
        ),
        dividerColor: const Color(0xFFE8EDF2),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E6ED)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E6ED)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      home: const AppShell(),
    );
  }
}


class _ColumnSpec {
  final String key;
  final String label;
  final int flex;
  const _ColumnSpec(this.key, this.label, [this.flex = 2]);
}

class _ColumnSettingsStore {
  static Map<String, List<String>> _values = {};
  static Map<String, double> _widths = {};
  static bool _loaded = false;
  static Future<void>? _loading;

  static Future<void> _load() async {
    if (_loaded) return;
    _loading ??= () async {
      try {
        final root = Platform.environment['APPDATA'] ??
            Platform.environment['LOCALAPPDATA'] ??
            Platform.environment['HOME'] ??
            Directory.systemTemp.path;
        final directory = Directory('$root${Platform.pathSeparator}MedialogN3');
        final file = File('${directory.path}${Platform.pathSeparator}column_preferences.json');
        if (await file.exists()) {
          final decoded = jsonDecode(await file.readAsString());
          if (decoded is Map<String, dynamic>) {
            _values = decoded.entries
                .where((entry) => entry.key != '_widths')
                .fold<Map<String, List<String>>>({}, (map, entry) {
                  map[entry.key] = entry.value is List
                      ? (entry.value as List).whereType<String>().toList()
                      : <String>[];
                  return map;
                });
            final storedWidths = decoded['_widths'];
            if (storedWidths is Map) {
              _widths = storedWidths.map((key, value) => MapEntry(
                key.toString(), value is num ? value.toDouble() : 180.0));
            }
          }
        }
      } catch (_) {
        _values = {};
      }
      _loaded = true;
    }();
    await _loading;
  }

  static Future<List<String>> get(String screen, List<_ColumnSpec> options) async {
    await _load();
    final saved = _values[screen];
    if (saved == null) {
      return options.map((e) => e.key).where((key) =>
        _defaultColumns[screen]?.contains(key) ?? true).toList();
    }
    final allowed = options.map((e) => e.key).toSet();
    final result = saved.where(allowed.contains).toList();
    return result.isEmpty ? options.map((e) => e.key).take(1).toList() : result;
  }

  static double width(String screen, String key) => _widths['$screen:$key'] ?? 180.0;

  static Future<void> setWidth(String screen, String key, double value) async {
    await _load();
    _widths['$screen:$key'] = value.clamp(90.0, 360.0);
    final root = Platform.environment['APPDATA'] ??
        Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['HOME'] ?? Directory.systemTemp.path;
    final directory = Directory('$root${Platform.pathSeparator}MedialogN3');
    await directory.create(recursive: true);
    final file = File('${directory.path}${Platform.pathSeparator}column_preferences.json');
    await file.writeAsString(jsonEncode({..._values, '_widths': _widths}), flush: true);
  }

  static Future<void> set(String screen, List<String> columns) async {
    await _load();
    _values[screen] = columns;
    final root = Platform.environment['APPDATA'] ??
        Platform.environment['LOCALAPPDATA'] ??
        Platform.environment['HOME'] ??
        Directory.systemTemp.path;
    final directory = Directory('$root${Platform.pathSeparator}MedialogN3');
    await directory.create(recursive: true);
    final file = File('${directory.path}${Platform.pathSeparator}column_preferences.json');
    await file.writeAsString(jsonEncode({..._values, '_widths': _widths}), flush: true);
  }
}


final _patientColumns = <_ColumnSpec>[
  const _ColumnSpec('PATIENTS_ID', 'ID записи пациента · int', 2),
  const _ColumnSpec('EMK_SINHRO', 'EMK_SINHRO · bit', 2),
  const _ColumnSpec('MEDECINS_MODIFY_ID', 'MEDECINS_MODIFY_ID · int', 2),
  const _ColumnSpec('CREATE_DATE_TIME', 'Дата создания ЭМК · datetime', 2),
  const _ColumnSpec('MODIFY_DATE_TIME', 'MODIFY_DATE_TIME · datetime', 2),
  const _ColumnSpec('DERN_CONS', 'DERN_CONS · datetime', 2),
  const _ColumnSpec('PL_SUBJ_ID', 'PL_SUBJ_ID · int', 2),
  const _ColumnSpec('PL_PATGR_ID', 'PL_PATGR_ID · int', 2),
  const _ColumnSpec('AGE', 'AGE · numeric', 2),
  const _ColumnSpec('SV_LAB', 'SV_LAB · text', 2),
  const _ColumnSpec('SV_LAF', 'SV_LAF · text', 2),
  const _ColumnSpec('F_PRINCPERC', 'F_PRINCPERC · numeric', 2),
  const _ColumnSpec('C_COMP', 'C_COMP · int', 2),
  const _ColumnSpec('F_PERC', 'F_PERC · numeric', 2),
  const _ColumnSpec('IMC', 'IMC · numeric', 2),
  const _ColumnSpec('SIGEMS_IPP', 'SIGEMS_IPP · int', 2),
  const _ColumnSpec('MEDECIN_REFERENT', 'MEDECIN_REFERENT · bit', 2),
  const _ColumnSpec('DUP_CHECK_DATE', 'Дата проверки дублей · datetime', 2),
  const _ColumnSpec('LPU_CLINK_PATIENTS', 'ЛПУ прикрепления · int', 2),
  const _ColumnSpec('PASPORT_LPU_FM_ORG_ID', 'PASPORT_LPU_FM_ORG_ID · int', 2),
  const _ColumnSpec('ORGANIZACIYA_MESTO_RABOTY', 'ORGANIZACIYA_MESTO_RABOTY · int', 2),
  const _ColumnSpec('N_OMON', 'Номер ЭМК · varchar', 2),
  const _ColumnSpec('NOMER_MEDICISKOJ_KART', 'Медицинская карта № · varchar', 2),
  const _ColumnSpec('NOM', 'Фамилия · varchar', 2),
  const _ColumnSpec('PRENOM', 'Имя · varchar', 2),
  const _ColumnSpec('PATRONYME', 'Отчество · varchar', 2),
  const _ColumnSpec('FIO', 'ФИО · varchar', 2),
  const _ColumnSpec('POL', 'Пол · int', 2),
  const _ColumnSpec('NE_LE', 'Дата рождения · datetime', 2),
  const _ColumnSpec('FM_ORG_ID', 'FM_ORG_ID · int', 2),
  const _ColumnSpec('VES', 'Вес · numeric', 2),
  const _ColumnSpec('ROST', 'Рост · numeric', 2),
  const _ColumnSpec('PROIS_OGDENIE', 'PROIS_OGDENIE · int', 2),
  const _ColumnSpec('MEDECINS_CREATE_ID', 'MEDECINS_CREATE_ID · int', 2),
  const _ColumnSpec('DOSSIER_EXIT', 'Умер · bit', 2),
  const _ColumnSpec('DATA_SMERTI', 'Дата смерти · datetime', 2),
  const _ColumnSpec('ARCHIVE', 'Архивный · bit', 2),
  const _ColumnSpec('ALSAC', 'ALSAC · bit', 2),
  const _ColumnSpec('N_OMON_CHILD', 'N_OMON_CHILD · varchar', 2),
  const _ColumnSpec('GOD_ROGDENIQ', 'GOD_ROGDENIQ · varchar', 2),
  const _ColumnSpec('EMAIL', 'Электронная почта · varchar', 2),
  const _ColumnSpec('MMK', 'MMK · varchar', 2),
  const _ColumnSpec('DUBL_NOMERA', 'DUBL_NOMERA · varchar', 2),
  const _ColumnSpec('SHETHIK_MEDKART', 'SHETHIK_MEDKART · numeric', 2),
  const _ColumnSpec('DLQ_MAKROSA_MEDKART', 'DLQ_MAKROSA_MEDKART · bit', 2),
  const _ColumnSpec('NOMER_POMS', 'Номер полиса ОМС · varchar', 2),
  const _ColumnSpec('SERIQ_POMS', 'Серия полиса ОМС · varchar', 2),
  const _ColumnSpec('OMS', 'ОМС · bit', 2),
  const _ColumnSpec('VID_OMS', 'VID_OMS · int', 2),
  const _ColumnSpec('PRIZNAK_OMS_MOSKVA', 'PRIZNAK_OMS_MOSKVA · int', 2),
  const _ColumnSpec('PRIZNAK_OMS_REGION', 'PRIZNAK_OMS_REGION · int', 2),
  const _ColumnSpec('BYDGET', 'BYDGET · bit', 2),
  const _ColumnSpec('VID_BYDGETA', 'VID_BYDGETA · int', 2),
  const _ColumnSpec('PLATN_J', 'PLATN_J · bit', 2),
  const _ColumnSpec('DMS', 'ДМС · bit', 2),
  const _ColumnSpec('VID_DMS', 'VID_DMS · int', 2),
  const _ColumnSpec('GITEL_GORODA_SELA', 'GITEL_GORODA_SELA · int', 2),
  const _ColumnSpec('PROPISKA', 'PROPISKA · int', 2),
  const _ColumnSpec('INDEKS', 'INDEKS · varchar', 2),
  const _ColumnSpec('STRANA1', 'STRANA1 · int', 2),
  const _ColumnSpec('STRANA', 'STRANA · varchar', 2),
  const _ColumnSpec('KOD_TERRITORII', 'KOD_TERRITORII · int', 2),
  const _ColumnSpec('OBLAST', 'OBLAST · varchar', 2),
  const _ColumnSpec('RAJON_ROSSII', 'RAJON_ROSSII · int', 2),
  const _ColumnSpec('RAJON', 'RAJON · varchar', 2),
  const _ColumnSpec('KOD_NASELENNOGO_PUNKTA', 'KOD_NASELENNOGO_PUNKTA · int', 2),
  const _ColumnSpec('OBLAST_GOROD', 'OBLAST_GOROD · int', 2),
  const _ColumnSpec('NASELENN_J_PUNKT', 'Населённый пункт · varchar', 2),
  const _ColumnSpec('RAYON_GORODA', 'RAYON_GORODA · varchar', 2),
  const _ColumnSpec('ULICA_MOSKVA1', 'ULICA_MOSKVA1 · int', 2),
  const _ColumnSpec('ULICA_MOSKVA', 'ULICA_MOSKVA · int', 2),
  const _ColumnSpec('ULICA', 'ULICA · varchar', 2),
  const _ColumnSpec('DOM', 'DOM · varchar', 2),
  const _ColumnSpec('KORPUS', 'KORPUS · varchar', 2),
  const _ColumnSpec('STROENIE', 'STROENIE · varchar', 2),
  const _ColumnSpec('KVARTIRA', 'KVARTIRA · varchar', 2),
  const _ColumnSpec('POD_EZD', 'POD_EZD · varchar', 2),
  const _ColumnSpec('ETAG', 'ETAG · varchar', 2),
  const _ColumnSpec('KOD_DOMOFON', 'KOD_DOMOFON · varchar', 2),
  const _ColumnSpec('ADRES_PO_PROPISKE', 'Адрес постоянного места жительства · text', 2),
  const _ColumnSpec('ADRES_FAKTIHESKIJ', 'Адрес регистрации по месту пребывания · text', 2),
  const _ColumnSpec('TEL', 'Телефон · varchar', 2),
  const _ColumnSpec('MOBIL_TELEFON', 'Мобильный телефон · varchar', 2),
  const _ColumnSpec('SNILS', 'СНИЛС · varchar', 2),
  const _ColumnSpec('ISTOHNIK_FINANSIROVANIQ', 'ISTOHNIK_FINANSIROVANIQ · int', 2),
  const _ColumnSpec('DOKUMENT_UDOSTOVERQYHIJ_P', 'DOKUMENT_UDOSTOVERQYHIJ_P · varchar', 2),
  const _ColumnSpec('DOKUMENT_L_GOTA', 'DOKUMENT_L_GOTA · varchar', 2),
  const _ColumnSpec('KOGDA_V_DAN_L_GOTA', 'KOGDA_V_DAN_L_GOTA · datetime', 2),
  const _ColumnSpec('KEM_V_DAN_L_GOTA', 'KEM_V_DAN_L_GOTA · varchar', 2),
  const _ColumnSpec('DOKUMENT_O_L_GOTE', 'DOKUMENT_O_L_GOTE · text', 2),
  const _ColumnSpec('INVALIDNOST', 'Инвалидность · int', 2),
  const _ColumnSpec('STEPEN_INVALIDNOSTI', 'STEPEN_INVALIDNOSTI · int', 2),
  const _ColumnSpec('DISPANSERNAQ_GRUPPA', 'Диспансерная группа · int', 2),
  const _ColumnSpec('DATA_POSTANOVKI_NA_UHET', 'Дата постановки на учёт · datetime', 2),
  const _ColumnSpec('DATA_SNQTIQ_S_UHETA', 'DATA_SNQTIQ_S_UHETA · datetime', 2),
  const _ColumnSpec('NOMER_LPU', 'NOMER_LPU · numeric', 2),
  const _ColumnSpec('UHASTOK', 'UHASTOK · numeric', 2),
  const _ColumnSpec('INOSTRANN_J_GRAGDANIN', 'INOSTRANN_J_GRAGDANIN · bit', 2),
  const _ColumnSpec('GRAGDANSTVO', 'GRAGDANSTVO · varchar', 2),
  const _ColumnSpec('NACIONAL_NOST', 'NACIONAL_NOST · varchar', 2),
  const _ColumnSpec('VID_DOKUMENTA', 'VID_DOKUMENTA · int', 2),
  const _ColumnSpec('SERIQ_DOKUMENTA', 'SERIQ_DOKUMENTA · varchar', 2),
  const _ColumnSpec('PASPORT_N', 'PASPORT_N · varchar', 2),
  const _ColumnSpec('KOGDA_V_DAN', 'KOGDA_V_DAN · datetime', 2),
  const _ColumnSpec('KEM_V_DAN', 'KEM_V_DAN · varchar', 2),
  const _ColumnSpec('UDOSTOVERENIE_LIHNOSTI', 'UDOSTOVERENIE_LIHNOSTI · text', 2),
  const _ColumnSpec('OTHESTVO_RODITELQ', 'OTHESTVO_RODITELQ · varchar', 2),
  const _ColumnSpec('IMQ_RODITELQ', 'IMQ_RODITELQ · varchar', 2),
  const _ColumnSpec('FAMILIQ_RODITELQ', 'FAMILIQ_RODITELQ · varchar', 2),
  const _ColumnSpec('DOKUMENT_RODITELQ', 'DOKUMENT_RODITELQ · bit', 2),
  const _ColumnSpec('PORQDKOV_J_NOMER_REBENKA', 'PORQDKOV_J_NOMER_REBENKA · varchar', 2),
  const _ColumnSpec('DOKUMENT_V_ROLI_POLISA', 'DOKUMENT_V_ROLI_POLISA · bit', 2),
  const _ColumnSpec('SOCIAL_N_J_STATUS', 'SOCIAL_N_J_STATUS · varchar', 2),
  const _ColumnSpec('SOCIAL_N_J_STATUS1', 'SOCIAL_N_J_STATUS1 · int', 2),
  const _ColumnSpec('RABOTA1', 'RABOTA1 · int', 2),
  const _ColumnSpec('RABOTA', 'RABOTA · varchar', 2),
  const _ColumnSpec('DOLGNOST', 'DOLGNOST · varchar', 2),
  const _ColumnSpec('RAB_TEL', 'RAB_TEL · varchar', 2),
  const _ColumnSpec('FAKS', 'FAKS · varchar', 2),
  const _ColumnSpec('PRIMEHANIE', 'PRIMEHANIE · text', 2),
  const _ColumnSpec('KATEGORIQ', 'KATEGORIQ · int', 2),
  const _ColumnSpec('APTEHNAQ_KATEGORIQ', 'APTEHNAQ_KATEGORIQ · int', 2),
  const _ColumnSpec('KATEGORIQ_L_GOTNOSTI', 'KATEGORIQ_L_GOTNOSTI · varchar', 2),
  const _ColumnSpec('GOSPITALIZIROVAN', 'GOSPITALIZIROVAN · bit', 2),
  const _ColumnSpec('ISTORIYA_RODOV', 'ISTORIYA_RODOV · int', 2),
  const _ColumnSpec('TERAPEVT', 'TERAPEVT · int', 2),
  const _ColumnSpec('NAPRAVLENIE', 'NAPRAVLENIE · varchar', 2),
  const _ColumnSpec('NAPRAVLENIE_S', 'NAPRAVLENIE_S · datetime', 2),
  const _ColumnSpec('NAPRAVLENIE_PO', 'NAPRAVLENIE_PO · datetime', 2),
  const _ColumnSpec('PRIZNAK_DVIGENIQ', 'PRIZNAK_DVIGENIQ · int', 2),
  const _ColumnSpec('NOMER_KMS', 'NOMER_KMS · varchar', 2),
  const _ColumnSpec('SERIQ_KMS', 'SERIQ_KMS · varchar', 2),
  const _ColumnSpec('SOCIAL_NAQ_GRUPPA_DLQ_089', 'SOCIAL_NAQ_GRUPPA_DLQ_089 · varchar', 2),
  const _ColumnSpec('KATEGORIIQ_BOL_NOGO_DLQ_0', 'KATEGORIIQ_BOL_NOGO_DLQ_0 · varchar', 2),
  const _ColumnSpec('DETSKOE_UHREGDENIE', 'DETSKOE_UHREGDENIE · varchar', 2),
  const _ColumnSpec('PRIZYVNIK', 'PRIZYVNIK · bit', 2),
  const _ColumnSpec('REG', 'REG · bit', 2),
  const _ColumnSpec('SOGLASIE_POLUCHENO', 'SOGLASIE_POLUCHENO · bit', 2),
  const _ColumnSpec('SUPRUG', 'SUPRUG · int', 2),
  const _ColumnSpec('KOD_DONORA', 'KOD_DONORA · varchar', 2),
  const _ColumnSpec('NOT_IDENTIFIED', 'NOT_IDENTIFIED · bit', 2),
  const _ColumnSpec('WEB_PLANNING_LOCKED', 'WEB_PLANNING_LOCKED · bit', 2),
  const _ColumnSpec('KARTA_V_ARHIVE', 'KARTA_V_ARHIVE · bit', 2),
  const _ColumnSpec('NOT_SEND_SMS', 'NOT_SEND_SMS · bit', 2),
  const _ColumnSpec('NOT_SEND_MAILING_SMS', 'NOT_SEND_MAILING_SMS · bit', 2),
  const _ColumnSpec('KATEGORIQ_L_GOT', 'KATEGORIQ_L_GOT · int', 2),
  const _ColumnSpec('FIO_TRENERA', 'FIO_TRENERA · varchar', 2),
  const _ColumnSpec('TEL_TRENERA', 'TEL_TRENERA · varchar', 2),
  const _ColumnSpec('FIO_SPORTIVNOGO_VRACHA', 'FIO_SPORTIVNOGO_VRACHA · varchar', 2),
  const _ColumnSpec('TEL_SPORTIVNOGO_VRACHA', 'TEL_SPORTIVNOGO_VRACHA · varchar', 2),
  const _ColumnSpec('SPORTIVNYY_RAZRYAD', 'SPORTIVNYY_RAZRYAD · int', 2),
  const _ColumnSpec('SOSTAV', 'SOSTAV · int', 2),
  const _ColumnSpec('E_MAIL', 'E_MAIL · varchar', 2),
  const _ColumnSpec('SEMEYNOE_POLOZHENIE', 'SEMEYNOE_POLOZHENIE · int', 2),
  const _ColumnSpec('NALICHIE_DETEY', 'NALICHIE_DETEY · bit', 2),
  const _ColumnSpec('SPORTIVNYY_VRACH', 'SPORTIVNYY_VRACH · int', 2),
  const _ColumnSpec('OBRAZOVANIE', 'OBRAZOVANIE · int', 2),
  const _ColumnSpec('KLASS_SHKOLY', 'KLASS_SHKOLY · numeric', 2),
  const _ColumnSpec('MESTO_RABOTY_ADRES', 'MESTO_RABOTY_ADRES · varchar', 2),
  const _ColumnSpec('PROFESSIYA', 'PROFESSIYA · varchar', 2),
  const _ColumnSpec('NAZVANIE_LECHEBNOGO_UCHRE', 'NAZVANIE_LECHEBNOGO_UCHRE · varchar', 2),
  const _ColumnSpec('ADRES_LECHEBNOGO_UCHREZHD', 'ADRES_LECHEBNOGO_UCHREZHD · varchar', 2),
  const _ColumnSpec('SEZONNOST_SPORTA', 'SEZONNOST_SPORTA · int', 2),
  const _ColumnSpec('PLACE_OF_BIRTH_COUNTRY', 'PLACE_OF_BIRTH_COUNTRY · int', 2),
  const _ColumnSpec('PLACE_OF_BIRTH_OBLAST', 'PLACE_OF_BIRTH_OBLAST · int', 2),
  const _ColumnSpec('PLACE_OF_BIRTH_REGION', 'PLACE_OF_BIRTH_REGION · int', 2),
  const _ColumnSpec('PLACE_OF_BIRTH_CITY', 'PLACE_OF_BIRTH_CITY · int', 2),
  const _ColumnSpec('PLACE_OF_BIRTH_COUNTRY_TE', 'PLACE_OF_BIRTH_COUNTRY_TE · varchar', 2),
  const _ColumnSpec('PLACE_OF_BIRTH_REGION_TEX', 'PLACE_OF_BIRTH_REGION_TEX · varchar', 2),
  const _ColumnSpec('PLACE_OF_BIRTH_CITY_TEXT', 'PLACE_OF_BIRTH_CITY_TEXT · varchar', 2),
  const _ColumnSpec('TESTOVYY_PACIENT', 'TESTOVYY_PACIENT · bit', 2),
  const _ColumnSpec('LPU_PRIKREPLENIYA', 'LPU_PRIKREPLENIYA · int', 2),
  const _ColumnSpec('NET_V_KLADRE', 'NET_V_KLADRE · bit', 2),
  const _ColumnSpec('VTOROE_MESTO_RABOTY', 'VTOROE_MESTO_RABOTY · varchar', 2),
  const _ColumnSpec('DOLZHNOST_VTORAYA_', 'DOLZHNOST_VTORAYA_ · varchar', 2),
  const _ColumnSpec('ADDRESS_SMO', 'ADDRESS_SMO · varchar', 2),
  const _ColumnSpec('PODRAZDELENIE', 'PODRAZDELENIE · varchar', 2),
  const _ColumnSpec('kontingent_str', 'kontingent_str · varchar', 2),
  const _ColumnSpec('PROFESSIYA_SSYLKA_', 'PROFESSIYA_SSYLKA_ · int', 2),
  const _ColumnSpec('NUMERO_MEDTR', 'NUMERO_MEDTR · varchar', 2),
  const _ColumnSpec('C_PRINC', 'C_PRINC · int', 2),
  const _ColumnSpec('AGE_AUTO', 'AGE_AUTO · numeric', 2),
  const _ColumnSpec('MEDECINS_ID', 'MEDECINS_ID · int', 2),
  const _ColumnSpec('KRN_CREATE_DATE', 'Дата создания записи · datetime', 2),
  const _ColumnSpec('KRN_CREATE_USER_ID', 'KRN_CREATE_USER_ID · int', 2),
  const _ColumnSpec('KRN_MODIFY_DATE', 'KRN_MODIFY_DATE · datetime', 2),
  const _ColumnSpec('KRN_MODIFY_USER_ID', 'KRN_MODIFY_USER_ID · int', 2),
  const _ColumnSpec('KRN_CREATE_DATABASE_ID', 'KRN_CREATE_DATABASE_ID · int', 2),
  const _ColumnSpec('KRN_MODIFY_DATABASE_ID', 'KRN_MODIFY_DATABASE_ID · int', 2),
  const _ColumnSpec('KRN_GUID', 'KRN_GUID · varchar', 2),
  const _ColumnSpec('Date_LPU_clink', 'Date_LPU_clink · datetime', 2),
  const _ColumnSpec('DATE_LAST_MED_EXAMS', 'Дата последней диспансеризации · datetime', 2),
  const _ColumnSpec('PAT_1C_ID', 'PAT_1C_ID · varchar', 2),
  const _ColumnSpec('sms_consent', 'Согласие на СМС информирование · bit', 2),
  const _ColumnSpec('MSS_ID_CARD', 'MSS_ID_CARD · varchar', 2),
  const _ColumnSpec('CHLEN_SEM_I_1', 'CHLEN_SEM_I_1 · varchar', 2),
  const _ColumnSpec('CHLEN_SEM_I_2', 'CHLEN_SEM_I_2 · varchar', 2),
  const _ColumnSpec('ANALIZY_PO_EMAIL', 'ANALIZY_PO_EMAIL · int', 2),
  const _ColumnSpec('SOTRUDNIK', 'SOTRUDNIK · bit', 2),
  const _ColumnSpec('NOMER_SAN', 'NOMER_SAN · varchar', 2),
  const _ColumnSpec('SURNAME_IO', 'SURNAME_IO · varchar', 2),
  const _ColumnSpec('VYDANO_IDS', 'VYDANO_IDS · bit', 2),
  const _ColumnSpec('ISTOCHNIK_INFORMIROVANIYA', 'ISTOCHNIK_INFORMIROVANIYA · int', 2),
  const _ColumnSpec('ISTOCHNIK', 'ISTOCHNIK · int', 2),
  const _ColumnSpec('ISTOCHNIK_INFORMIROVANIYA_GCM', 'ISTOCHNIK_INFORMIROVANIYA_GCM · int', 2),
  const _ColumnSpec('KOD_PODRAZDELENIYA', 'KOD_PODRAZDELENIYA · varchar', 2),
  const _ColumnSpec('KOD_PODRAZDELENIYA_PASPOR', 'KOD_PODRAZDELENIYA_PASPOR · varchar', 2),
  const _ColumnSpec('INN', 'ИНН · varchar', 2),
  const _ColumnSpec('PROVERKA', 'PROVERKA · numeric', 2),
];

Map<String, String> _patientFieldValues({
  required String patientId,
  required String name,
  required String emk,
  String birth = '—',
  String sex = '—',
  String policy = '—',
  String address = '—',
  String phone = '—',
}) {
  final parts = name.split(' ');
  return {
    'PATIENTS_ID': patientId,
    'FIO': name,
    'NOM': parts.isNotEmpty ? parts.first : '—',
    'PRENOM': parts.length > 1 ? parts[1] : '—',
    'PATRONYME': parts.length > 2 ? parts.skip(2).join(' ') : '—',
    'N_OMON': emk,
    'NE_LE': birth,
    'POL': sex,
    'NOMER_POMS': policy,
    'MOBIL_TELEFON': phone,
    'TEL': phone,
    'ADRES_PO_PROPISKE': address,
    'NASELENN_J_PUNKT': 'Москва',
    'OMS': 'Да',
    'ARCHIVE': 'Нет',
  };
}

Map<String, Widget> _patientCells(Map<String, String> values) => {
  for (final column in _patientColumns)
    column.key: Text(values[column.key] ?? '—',
      maxLines: 2, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 10, color: Color(0xFF536579))),
};

String _patientIdFromEmk(String emk) {
  final digits = emk.replaceAll(RegExp(r'[^0-9]'), '');
  return 'PAT-${digits.isEmpty ? 'UNKNOWN' : digits}';
}

const _patientFilterOptions = <String>[
  'Все пациенты',
  'Алексеева Мария Викторовна',
  'Белов Андрей Сергеевич',
  'Васильева Елена Павловна',
  'Громов Дмитрий Олегович',
  'Демидова Наталья Игоревна',
  'Егоров Михаил Андреевич',
  'Жукова Ольга Николаевна',
  'Зайцев Павел Владимирович',
  'Ильина Татьяна Сергеевна',
  'Крылов Артём Евгеньевич',
  'Лебедева Анна Дмитриевна',
  'Макаров Сергей Петрович',
  'Никитина Ирина Алексеевна',
  'Осипов Владимир Михайлович',
  'Павлова Светлана Романовна',
  'Романов Кирилл Денисович',
  'Соколова Марина Юрьевна',
  'Тихонов Алексей Борисович',
  'Фёдорова Дарья Константиновна',
];

Widget _patientFilter(String value, ValueChanged<String> onChanged) =>
  SizedBox(width: 270, child: DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Фильтр по пациенту', isDense: true),
    items: _patientFilterOptions.map((name) =>
      DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))).toList(),
    onChanged: (next) => onChanged(next ?? 'Все пациенты'),
  ));


const _defaultColumns = <String, List<String>>{
  'queue': ['FIO', 'N_OMON', 'PATIENTS_ID', 'id', 'type', 'doctor', 'date', 'status'],
  'archive': ['FIO', 'N_OMON', 'PATIENTS_ID', 'id', 'type', 'patient', 'date', 'status'],
  'iemk': ['PATIENTS_ID', 'FIO', 'N_OMON', 'NE_LE', 'NOMER_POMS', 'DOCUMENTS', 'ALERTS'],
  'audit': ['FIO', 'N_OMON', 'PATIENTS_ID', 'time', 'event', 'object', 'user', 'result'],
};

class _ColumnSettingsButton extends StatelessWidget {
  final String screen;
  final List<_ColumnSpec> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _ColumnSettingsButton({
    required this.screen,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Настроить отображаемые колонки',
    icon: const Icon(Icons.settings_outlined, size: 19),
    color: const Color(0xFF60758A),
    onPressed: () async {
      final draft = selected.toSet();
      final order = [...selected, ...options.map((e) => e.key).where((key) => !selected.contains(key))];
      final widths = {for (final option in options) option.key: _ColumnSettingsStore.width(screen, option.key)};
      final result = await showDialog<({List<String> order, Map<String, double> widths})>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Настройка колонок'),
            content: SizedBox(
              width: 560,
              height: 540,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Перетаскивайте строки для изменения порядка. Настройте видимость и ширину колонок.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF718095))),
                const SizedBox(height: 10),
                Expanded(
                  child: ReorderableListView(
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) => setDialogState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = order.removeAt(oldIndex);
                      order.insert(newIndex, item);
                    }),
                    children: [
                      for (var index = 0; index < order.length; index++)
                        Builder(builder: (context) {
                          final key = order[index];
                          final option = options.firstWhere((item) => item.key == key);
                          final width = widths[key] ?? 180.0;
                          return Container(
                            key: ValueKey(key),
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFE7ECF1)))),
                            child: Row(children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.drag_indicator, color: Color(0xFF8292A3), size: 19)),
                              ),
                              SizedBox(width: 245, child: CheckboxListTile(
                                dense: true, contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                value: draft.contains(key),
                                title: Text(option.label, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11)),
                                onChanged: (value) => setDialogState(() {
                                  if (value == true) { draft.add(key); } else { draft.remove(key); }
                                }),
                              )),
                              Expanded(child: Slider(
                                min: 90, max: 360, divisions: 54,
                                value: width.clamp(90.0, 360.0),
                                label: '${width.round()} px',
                                onChanged: (value) => setDialogState(() => widths[key] = value),
                              )),
                              SizedBox(width: 48, child: Text('${width.round()} px',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF60758A)))),
                            ]),
                          );
                        }),
                    ],
                  ),
                ),
                if (draft.isEmpty) const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Необходимо оставить хотя бы одну колонку.',
                    style: TextStyle(fontSize: 11, color: Color(0xFFC34E4E)))),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
              TextButton(onPressed: () => setDialogState(() {
                draft..clear()..addAll(options.map((e) => e.key));
              }), child: const Text('Выбрать все')),
              FilledButton(
                onPressed: draft.isEmpty ? null : () => Navigator.pop(dialogContext,
                  (order: order.where(draft.contains).toList(), widths: widths)),
                child: const Text('Сохранить')),
            ],
          ),
        ),
      );
      if (result != null) {
        try {
          await _ColumnSettingsStore.set(screen, result.order);
          for (final entry in result.widths.entries) {
            await _ColumnSettingsStore.setWidth(screen, entry.key, entry.value);
          }
          onChanged(result.order);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Настройки колонок сохранены на этом компьютере.')),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось сохранить настройки колонок.')),
            );
          }
        }
      }
    },
  );
}

class _HorizontalTable extends StatefulWidget {
  final Widget child;
  const _HorizontalTable({required this.child});
  @override
  State<_HorizontalTable> createState() => _HorizontalTableState();
}
class _HorizontalTableState extends State<_HorizontalTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      },
    ),
    child: Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      thickness: 12,
      radius: const Radius.circular(8),
      notificationPredicate: (notification) => notification.depth == 0,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        primary: false,
        child: SizedBox(
          height: 520,
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            thickness: 10,
            radius: const Radius.circular(8),
            notificationPredicate: (notification) => notification.depth == 0,
            child: SingleChildScrollView(
              controller: _verticalController,
              primary: false,
              child: widget.child,
            ),
          ),
        ),
      ),
    ),
  );
}

double _columnWidth(String screen, _ColumnSpec column) => _ColumnSettingsStore.width(screen, column.key);

List<_ColumnSpec> _orderedVisibleColumns(List<_ColumnSpec> columns, List<String> order) {
  final byKey = {for (final column in columns) column.key: column};
  return [for (final key in order) if (byKey.containsKey(key)) byKey[key]!];
}

double _columnTotalWidth(String screen, List<_ColumnSpec> columns) =>
    columns.fold(0.0, (total, column) => total + _columnWidth(screen, column));

Widget _columnHeaderRow(List<_ColumnSpec> columns, {required double width, required String screen}) =>
    SizedBox(
      width: _columnTotalWidth(screen, columns),
      child: Row(children: [
        for (final column in columns)
          SizedBox(
            width: _columnWidth(screen, column),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Text(column.label.toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF8794A3))),
            ),
          ),
      ]),
    );

Widget _columnDataRow(List<_ColumnSpec> columns, Map<String, Widget> cells, {required double width, required String screen}) =>
    SizedBox(
      width: _columnTotalWidth(screen, columns),
      child: Row(children: [
        for (final column in columns)
          SizedBox(
            width: _columnWidth(column),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: cells[column.key] ??
                const Text('Не указано', style: TextStyle(fontSize: 10, color: Color(0xFF8794A3))),
            ),
          ),
      ]),
    );

class _NavItem {
  final String title;
  final IconData icon;
  const _NavItem(this.title, this.icon);
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Scaffold(
          appBar: compact
              ? AppBar(
                  title: const Text('MEDIALOG N3'),
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  actions: const [
                    Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: _DemoBadge(),
                    ),
                  ],
                )
              : null,
          drawer: compact
              ? Drawer(
                  child: _Sidebar(
                    selectedIndex: _selectedIndex,
                    onSelected: (index) {
                      setState(() => _selectedIndex = index);
                      Navigator.pop(context);
                    },
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!compact)
                SizedBox(
                  width: 258,
                  child: _Sidebar(
                    selectedIndex: _selectedIndex,
                    onSelected: (index) => setState(() => _selectedIndex = index),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (!compact) const _TopBar(),
                    Expanded(
                      child: _PageHost(index: _selectedIndex),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _Sidebar({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF142B45),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 18, 28),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2878B8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.monitor_heart_outlined, color: Colors.white, size: 25),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MEDIALOG N3', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: .4)),
                        SizedBox(height: 3),
                        Text('INTEGRATION DESKTOP', style: TextStyle(color: Color(0xFF9FB3C8), fontSize: 9, letterSpacing: 1.1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 16, 10),
              child: Text('РАБОЧЕЕ ПРОСТРАНСТВО', style: TextStyle(color: Color(0xFF829AB1), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
            for (var i = 0; i < _navItems.length; i++)
              _SidebarTile(
                item: _navItems[i],
                selected: selectedIndex == i,
                onTap: () => onSelected(i),
              ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Color(0xFF30465D)),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Color(0xFF42C59A)),
                      SizedBox(width: 8),
                      Text('Демонстрационный режим', style: TextStyle(color: Color(0xFFB8C9D9), fontSize: 11)),
                    ],
                  ),
                  SizedBox(height: 7),
                  Text('UI Prototype 0.1.0', style: TextStyle(color: Color(0xFF829AB1), fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? const Color(0xFF254663) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(item.icon, size: 19, color: selected ? Colors.white : const Color(0xFFA9BBCB)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFD0DCE6),
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected) const Icon(Icons.chevron_right, color: Color(0xFF9BC7E8), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF2))),
      ),
      child: const Row(
        children: [
          Text('Интеграция с ЕГИСЗ', style: TextStyle(color: Color(0xFF617286), fontSize: 12)),
          Spacer(),
          Icon(Icons.cloud_done_outlined, size: 17, color: Color(0xFF269B77)),
          SizedBox(width: 7),
          Text('Локальный режим', style: TextStyle(fontSize: 11, color: Color(0xFF526477))),
          SizedBox(width: 20),
          _DemoBadge(),
          SizedBox(width: 18),
          CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE7EFF7),
            child: Icon(Icons.person_outline, size: 18, color: Color(0xFF315879)),
          ),
          SizedBox(width: 9),
          Text('Оператор', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('DEMO', style: TextStyle(color: Color(0xFF96610A), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .6)),
    );
  }
}

class _PageHost extends StatelessWidget {
  final int index;
  const _PageHost({required this.index});

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => const DashboardPage(),
      1 => const PreflightPage(),
      2 => const QueuePage(),
      3 => const ArchivePage(),
      4 => const IemkPage(),
      5 => const AuditPage(),
      _ => const SettingsPage(),
    };
  }
}

class _PagePadding extends StatefulWidget {
  final Widget child;
  const _PagePadding({required this.child});
  @override
  State<_PagePadding> createState() => _PagePaddingState();
}
class _PagePaddingState extends State<_PagePadding> {
  final ScrollController _controller = ScrollController();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _controller, thumbVisibility: true, trackVisibility: true,
    interactive: true, thickness: 9, radius: const Radius.circular(8),
    child: SingleChildScrollView(controller: _controller,
      padding: const EdgeInsets.all(28),
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440), child: widget.child))),
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PagePadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageHeading(
            title: 'Панель управления',
            subtitle: 'Сводная информация о подготовке и передаче медицинских документов',
            trailing: _DemoBadge(),
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _MetricCard(title: 'Сформировано СЭМД', value: '1 248', note: '+12,4% к прошлой неделе', icon: Icons.description_outlined, color: Color(0xFF347DB5)),
              _MetricCard(title: 'Зарегистрировано', value: '1 106', note: '88,6% от сформированных', icon: Icons.check_circle_outline, color: Color(0xFF269B77)),
              _MetricCard(title: 'Ожидают обработки', value: '96', note: 'Документы в очереди', icon: Icons.hourglass_empty, color: Color(0xFFD99A2B)),
              _MetricCard(title: 'Требуют внимания', value: '46', note: 'Ошибки и блокировки', icon: Icons.error_outline, color: Color(0xFFD65A5A)),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 900;
              final readiness = const _ReadinessCard();
              final activity = const _ActivityCard();
              return wide
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 5, child: readiness),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: activity),
                    ])
                  : Column(children: [readiness, const SizedBox(height: 16), activity]);
            },
          ),
          const SizedBox(height: 20),
          const _RecentDocumentsCard(),
        ],
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  const _PageHeading({required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF1B2D40))),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF748396))),
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.title, required this.value, required this.note, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 245,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF718095), fontWeight: FontWeight.w600))),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon, size: 18, color: color),
                ),
              ]),
              const SizedBox(height: 14),
              Text(value, style: const TextStyle(fontSize: 29, height: 1, fontWeight: FontWeight.w800, color: Color(0xFF1B2D40))),
              const SizedBox(height: 9),
              Text(note, style: const TextStyle(fontSize: 10, color: Color(0xFF8794A3))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardTitle(title: 'Готовность к выгрузке', subtitle: 'Результаты предварительного контроля'),
            const SizedBox(height: 22),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('94,2%', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w800, color: Color(0xFF1B2D40))),
              const Spacer(),
              Text('1 176 из 1 248', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(value: .942, minHeight: 9, backgroundColor: Color(0xFFEAF0F4), color: Color(0xFF269B77)),
            ),
            const SizedBox(height: 20),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _CheckChip(label: 'ФРМО', detail: 'Проверено', ok: true),
                _CheckChip(label: 'ФРМР', detail: 'Проверено', ok: true),
                _CheckChip(label: 'УКЭП', detail: 'Проверено', ok: true),
                _CheckChip(label: 'СЭМД', detail: 'Замечания', ok: false),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Демонстрационные данные. Проверки с реестрами не выполняются.', style: TextStyle(fontSize: 10, color: Color(0xFF8996A4))),
          ],
        ),
      ),
    );
  }
}

class _CheckChip extends StatelessWidget {
  final String label;
  final String detail;
  final bool ok;
  const _CheckChip({required this.label, required this.detail, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF269B77) : const Color(0xFFD99A2B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ok ? Icons.check_circle : Icons.warning_amber_rounded, size: 15, color: color),
        const SizedBox(width: 6),
        Text('$label · $detail', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    const values = [145.0, 172.0, 160.0, 190.0, 180.0, 95.0, 164.0];
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _CardTitle(title: 'Активность выгрузки', subtitle: 'Количество документов за неделю'),
          const SizedBox(height: 24),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(values[i].toInt().toString(), style: const TextStyle(fontSize: 9, color: Color(0xFF78889A))),
                      const SizedBox(height: 5),
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: values[i] / 200,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(color: const Color(0xFF4A91C5), borderRadius: BorderRadius.circular(5)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(days[i], style: const TextStyle(fontSize: 9, color: Color(0xFF8794A3))),
                    ]),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          const Row(children: [
            Icon(Icons.circle, size: 8, color: Color(0xFF4A91C5)),
            SizedBox(width: 6),
            Text('Сформировано документов', style: TextStyle(fontSize: 10, color: Color(0xFF718095))),
          ]),
        ]),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _CardTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF24374A))),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF8492A1))),
    ]);
  }
}

class _RecentDocumentsCard extends StatelessWidget {
  const _RecentDocumentsCard();

  @override
  Widget build(BuildContext context) {
    const docs = [
      ('MED-001258', 'Протокол консультации', '23.11.2026 11:18', 'Готов к отправке', 0),
      ('MED-001257', 'Протокол лабораторного исследования', '23.11.2026 11:12', 'Ожидает проверки', 1),
      ('MED-001256', 'Выписной эпикриз', '23.11.2026 11:05', 'Ошибка CDA', 2),
      ('MED-001255', 'Протокол осмотра', '23.11.2026 10:58', 'Готов к отправке', 0),
      ('MED-001254', 'Протокол инструментального исследования', '23.11.2026 10:51', 'Ожидает проверки', 1),
      ('MED-001253', 'Направление', '23.11.2026 10:47', 'Готов к отправке', 0),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _CardTitle(title: 'Последние документы', subtitle: 'Недавние операции с СЭМД'),
          const SizedBox(height: 14),
          for (final d in docs)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF0F2F5)))),
              child: Row(children: [
                const Icon(Icons.description_outlined, color: Color(0xFF7890A5), size: 19),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: Text(d.$1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                Expanded(flex: 3, child: Text(d.$2, style: const TextStyle(fontSize: 11, color: Color(0xFF5F7082)))),
                Expanded(flex: 2, child: Text(d.$3, style: const TextStyle(fontSize: 10, color: Color(0xFF8996A4)))),
                _StatusBadge(label: d.$4, type: d.$5),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final int type;
  const _StatusBadge({required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      0 => const Color(0xFF238A69),
      1 => const Color(0xFFB47A18),
      _ => const Color(0xFFC34E4E),
    };
    final bg = switch (type) {
      0 => const Color(0xFFE8F6F0),
      1 => const Color(0xFFFFF4DE),
      _ => const Color(0xFFFCECEC),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

class PreflightPage extends StatelessWidget {
  const PreflightPage({super.key});

  @override
  Widget build(BuildContext context) {
    const checks = [
      ('ФРМО', 'Медицинская организация, подразделения, OID и актуальность сведений', 'Проверено', 0, Icons.apartment_outlined),
      ('ФРМР', 'Врач, СНИЛС, специальность и регистрационные сведения', 'Проверено', 0, Icons.medical_services_outlined),
      ('УКЭП врача', 'Владелец сертификата, срок действия, цепочка доверия и отзыв', 'Проверено', 0, Icons.person_outline),
      ('УКЭП организации', 'Сертификат юридического лица и реквизиты МО', 'Проверено', 0, Icons.business_outlined),
      ('Дата подписания', 'Действительность сертификата на момент подписания документа', 'Требует проверки', 1, Icons.event_available_outlined),
      ('Валидация СЭМД', 'Структура CDA, версия шаблона, обязательные поля и справочники', 'Есть ошибки', 2, Icons.code_outlined),
    ];
    return _PagePadding(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _PageHeading(title: 'Предварительный контроль', subtitle: 'Проверки до допуска СЭМД к отправке'),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF2878B8), size: 28),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Контроль готовности', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                SizedBox(height: 4),
                Text('Демонстрационный набор результатов. Интеграции с реестрами и криптопровайдером отключены.', style: TextStyle(fontSize: 11, color: Color(0xFF7D8B9A))),
              ])),
              FilledButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Демо: проверка выполнена на макетных данных.'))), icon: const Icon(Icons.refresh, size: 16), label: const Text('Запустить проверки')),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        for (final c in checks)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: const Color(0xFFF0F5F9), borderRadius: BorderRadius.circular(11)),
                  child: Icon(c.$5, color: const Color(0xFF47799E), size: 21),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(c.$2, style: const TextStyle(fontSize: 11, color: Color(0xFF7C8B9A))),
                ])),
                _StatusBadge(label: c.$3, type: c.$4),
                const SizedBox(width: 8),
                IconButton(onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(title: Text(c.$1), content: Text('Демонстрационный протокол проверки: ${c.$3}. Реальные запросы пока не выполняются.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть'))])), icon: const Icon(Icons.info_outline, size: 19)),
              ]),
            ),
          ),
      ]),
    );
  }
}

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  String filter = 'Все';
  String query = '';
  String patientFilter = 'Все пациенты';
  List<String> visibleColumns = _defaultColumns['queue']!;
  static final columns = <_ColumnSpec>[..._patientColumns,
    const _ColumnSpec('id', 'ID документа', 2),
    const _ColumnSpec('type', 'Тип СЭМД', 4),
    const _ColumnSpec('patient', 'Пациент', 3),
    const _ColumnSpec('emk', 'Номер ЭМК', 2),
    const _ColumnSpec('doctor', 'Врач', 2),
    const _ColumnSpec('date', 'Дата формирования', 2),
    const _ColumnSpec('status', 'Статус документа', 2),
  ];
  @override
  void initState() {
    super.initState();
    _ColumnSettingsStore.get('queue', columns).then((value) {
      if (mounted) setState(() => visibleColumns = value);
    });
  }

  final docs = <_Doc>[
    _Doc('MED-001258', 'Протокол консультации', 'Смирнова Н.В.', 'Алексеева Мария Викторовна', 'ЭМК-00018452', '23.11.2026 11:18', 'Готов к отправке', 0),
    _Doc('MED-001257', 'Протокол лабораторного исследования', 'Орлова М.Д.', 'Белов Андрей Сергеевич', 'ЭМК-00018451', '23.11.2026 11:12', 'Ожидает проверки', 1),
    _Doc('MED-001256', 'Выписной эпикриз', 'Петрова А.С.', 'Васильева Елена Павловна', 'ЭМК-00018450', '23.11.2026 11:05', 'Ошибка CDA', 2),
    _Doc('MED-001255', 'Протокол осмотра', 'Иванов И.И.', 'Громов Дмитрий Олегович', 'ЭМК-00018449', '23.11.2026 10:58', 'Готов к отправке', 0),
    _Doc('MED-001254', 'Протокол инструментального исследования', 'Кузнецова Е.В.', 'Демидова Наталья Игоревна', 'ЭМК-00018448', '23.11.2026 10:51', 'Ожидает проверки', 1),
    _Doc('MED-001253', 'Направление', 'Смирнова Н.В.', 'Егоров Михаил Андреевич', 'ЭМК-00018447', '23.11.2026 10:47', 'Готов к отправке', 0),
    _Doc('MED-001252', 'Справка', 'Орлова М.Д.', 'Жукова Ольга Николаевна', 'ЭМК-00018446', '23.11.2026 10:43', 'Ошибка УКЭП', 2),
    _Doc('MED-001251', 'Протокол консультации', 'Иванов И.И.', 'Зайцев Павел Владимирович', 'ЭМК-00018445', '23.11.2026 10:39', 'Готов к отправке', 0),
    _Doc('MED-001250', 'Протокол лабораторного исследования', 'Петрова А.С.', 'Ильина Татьяна Сергеевна', 'ЭМК-00018444', '23.11.2026 10:34', 'Готов к отправке', 0),
    _Doc('MED-001249', 'Выписной эпикриз', 'Кузнецова Е.В.', 'Крылов Артём Евгеньевич', 'ЭМК-00018443', '23.11.2026 10:29', 'Ожидает проверки', 1),
    _Doc('MED-001248', 'Протокол осмотра', 'Смирнова Н.В.', 'Лебедева Анна Дмитриевна', 'ЭМК-00018442', '23.11.2026 10:24', 'Готов к отправке', 0),
    _Doc('MED-001247', 'Протокол инструментального исследования', 'Орлова М.Д.', 'Макаров Сергей Петрович', 'ЭМК-00018441', '23.11.2026 10:17', 'Ошибка CDA', 2),
    _Doc('MED-001246', 'Направление', 'Иванов И.И.', 'Никитина Ирина Алексеевна', 'ЭМК-00018440', '23.11.2026 10:09', 'Готов к отправке', 0),
    _Doc('MED-001245', 'Протокол осмотра', 'Иванов И.И.', 'Осипов Владимир Михайлович', 'ЭМК-00018439', '23.11.2026 10:02', 'Готов к отправке', 0),
    _Doc('MED-001244', 'Выписной эпикриз', 'Петрова А.С.', 'Павлова Светлана Романовна', 'ЭМК-00018438', '23.11.2026 09:56', 'Ожидает проверки', 1),
    _Doc('MED-001243', 'Протокол лабораторного исследования', 'Сидоров П.П.', 'Романов Кирилл Денисович', 'ЭМК-00018437', '23.11.2026 09:48', 'Ошибка CDA', 2),
    _Doc('MED-001242', 'Направление', 'Иванов И.И.', 'Соколова Марина Юрьевна', 'ЭМК-00018436', '23.11.2026 09:41', 'Готов к отправке', 0),
    _Doc('MED-001241', 'Справка', 'Кузнецова Е.В.', 'Тихонов Алексей Борисович', 'ЭМК-00018435', '23.11.2026 09:35', 'Ошибка УКЭП', 2),
    _Doc('MED-001240', 'Протокол инструментального исследования', 'Петрова А.С.', 'Фёдорова Дарья Константиновна', 'ЭМК-00018434', '23.11.2026 09:28', 'Готов к отправке', 0),
    for (var i = 0; i < 80; i++)
      _Doc('MED-${(1239-i).toString().padLeft(6,'0')}',
        const ['Протокол осмотра','Протокол консультации','Лабораторное исследование','Направление'][i%4],
        const ['Иванов И.И.','Смирнова Н.В.','Петрова А.С.','Кузнецова Е.В.'][i%4],
        _patientFilterOptions[(i%(_patientFilterOptions.length-1))+1],
        'ЭМК-${(18433-i).toString().padLeft(8,'0')}',
        '22.11.2026 ${(8+i%12).toString().padLeft(2,'0')}:${(i*7%60).toString().padLeft(2,'0')}',
        const ['Готов к отправке','Ожидает проверки','Ошибка CDA','Ожидает подписи'][i%4],
        i%4==0 ? 0 : i%4==1 ? 1 : 2),

  ];

  @override
  Widget build(BuildContext context) {
    final filtered = docs.where((d) {
      final matchesFilter = filter == 'Все' || (filter == 'Готовы' && d.type == 0) || (filter == 'Ошибки' && d.type == 2);
      final matchesQuery = '${d.id} ${d.name} ${d.doctor} ${d.patient} ${d.emk}'.toLowerCase().contains(query.toLowerCase());
      final matchesPatient = patientFilter == 'Все пациенты' || d.patient == patientFilter;
      return matchesFilter && matchesQuery && matchesPatient;
    }).toList();
    return _PagePadding(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _PageHeading(title: 'Очередь СЭМД', subtitle: 'Подготовка, проверка и полуавтоматическая отправка документов'),
        const SizedBox(height: 20),
        const Wrap(spacing: 10, runSpacing: 10, children: [
          _MiniCount(label: 'Всего в очереди', value: '142'),
          _MiniCount(label: 'Готовы', value: '87'),
          _MiniCount(label: 'Ошибки', value: '19'),
        ]),
        const SizedBox(height: 18),
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск по ID, типу документа или врачу'),
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: 10),
            _patientFilter(patientFilter, (value) => setState(() => patientFilter = value)),
            const SizedBox(height: 12),
            Row(children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Все', label: Text('Все')),
                  ButtonSegment(value: 'Готовы', label: Text('Готовы')),
                  ButtonSegment(value: 'Ошибки', label: Text('Ошибки')),
                ],
                selected: {filter},
                onSelectionChanged: (v) => setState(() => filter = v.first),
                showSelectedIcon: false,
              ),
              const Spacer(),
              OutlinedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Демо: список обновлён.'))), icon: const Icon(Icons.refresh, size: 16), label: const Text('Обновить')),
            ]),
          ]),
        )),
        const SizedBox(height: 10),
        _patientFilter(patientFilter, (value) => setState(() => patientFilter = value)),
        const SizedBox(height: 12),
        Card(child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: _ColumnSettingsButton(
                screen: 'queue',
                options: columns,
                selected: visibleColumns,
                onChanged: (value) => setState(() => visibleColumns = value),
              ),
            ),
          ),
          _HorizontalTable(
            child: Column(children: [
              _columnHeaderRow(_orderedVisibleColumns(columns, visibleColumns), width: 0, screen: 'audit'),
              for (final d in filtered)
                InkWell(
                  onTap: () => showDialog(context: context, builder: (_) => _DocumentDialog(doc: d)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                    child: _columnDataRow(
                      _orderedVisibleColumns(columns, visibleColumns),
                      {
                        ..._patientCells(_patientFieldValues(patientId: d.patientId, name: d.patient, emk: d.emk)),
                        'id': Text(d.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        'type': Text(d.name, style: const TextStyle(fontSize: 11)),
                        'patient': Text(d.patient, style: const TextStyle(fontSize: 10)),
                        'emk': Text(d.emk, style: const TextStyle(fontSize: 10)),
                        'doctor': Text(d.doctor, style: const TextStyle(fontSize: 10, color: Color(0xFF68798A))),
                        'date': Text(d.date, style: const TextStyle(fontSize: 10, color: Color(0xFF8794A3))),
                        'status': _StatusBadge(label: d.status, type: d.type),
                      },
                      width: 0, screen: 'queue',
                    ),
                  ),
                ),
              if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Text('Документы не найдены')),
            ]),
          ),
        ])),
        const SizedBox(height: 12),
        const Text('Все записи и статусы на этой странице демонстрационные.', style: TextStyle(fontSize: 10, color: Color(0xFF8996A4))),
      ]),
    );
  }
}

class _Doc {
  final String id, name, doctor, patient, emk, date, status;
  final int type;
  const _Doc(this.id, this.name, this.doctor, this.patient, this.emk, this.date, this.status, this.type);

  // Связь документа с карточкой пациента по номеру ЭМК.
  String get patientId => _patientIdFromEmk(emk);
}

class _DocumentDialog extends StatelessWidget {
  final _Doc doc;
  const _DocumentDialog({required this.doc});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(doc.id),
      content: SizedBox(width: 460, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(doc.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        _InfoLine(label: 'ФИО пациента', value: doc.patient),
        _InfoLine(label: 'ЭМК (номер)', value: doc.emk),
        _InfoLine(label: 'Лечащий врач', value: doc.doctor),
        _InfoLine(label: 'Дата формирования', value: doc.date),
        _InfoLine(label: 'Статус документа', value: doc.status),
        const Divider(height: 24),
        const Text('Проверки', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const _CheckChip(label: 'ФРМО', detail: 'Проверено', ok: true),
        const SizedBox(height: 6),
        const _CheckChip(label: 'ФРМР', detail: 'Проверено', ok: true),
        const SizedBox(height: 6),
        const _CheckChip(label: 'УКЭП', detail: 'Проверено', ok: true),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.fact_check_outlined, size: 16, color: Color(0xFF718095)),
          const SizedBox(width: 7),
          const Expanded(child: Text('Проверка валидации N3', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          _StatusBadge(
            label: doc.type == 2 ? 'Не пройдена' : doc.type == 1 ? 'Есть замечания' : 'Пройдена',
            type: doc.type,
          ),
        ]),
        const SizedBox(height: 12),
        const Text('Карточка и результаты проверки показаны в демонстрационном режиме.', style: TextStyle(fontSize: 10, color: Color(0xFF8794A3))),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть'))],
    );
  }
}

class _MiniCount extends StatelessWidget {
  final String label, value;
  const _MiniCount({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE6EBF1)), borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7C8B9A))),
    ]),
  );
}

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});
  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  String query = '';
  String patientFilter = 'Все пациенты';
  _Doc? selectedDocument;
  List<String> visibleColumns = _defaultColumns['archive']!;
  static final columns = <_ColumnSpec>[..._patientColumns,
    const _ColumnSpec('id', 'ID документа', 2),
    const _ColumnSpec('type', 'Тип СЭМД', 4),
    const _ColumnSpec('patient', 'Пациент', 3),
    const _ColumnSpec('emk', 'Номер ЭМК', 2),
    const _ColumnSpec('doctor', 'Врач', 2),
    const _ColumnSpec('date', 'Дата формирования', 2),
    const _ColumnSpec('status', 'Статус', 2),
  ];

  @override
  void initState() {
    super.initState();
    _ColumnSettingsStore.get('archive', columns).then((value) {
      if (mounted) setState(() => visibleColumns = value);
    });
  }

  static final documents = <_Doc>[
    _Doc('MED-001258', 'Протокол консультации', 'Смирнова Н.В.', 'Алексеева Мария Викторовна', 'ЭМК-00018452', '23.11.2026 11:18', 'Зарегистрирован', 0),
    _Doc('MED-001255', 'Протокол осмотра', 'Иванов И.И.', 'Громов Дмитрий Олегович', 'ЭМК-00018449', '23.11.2026 10:58', 'Зарегистрирован', 0),
    _Doc('MED-001254', 'Протокол инструментального исследования', 'Кузнецова Е.В.', 'Демидова Наталья Игоревна', 'ЭМК-00018448', '23.11.2026 10:51', 'Ожидает регистрации', 1),
    _Doc('MED-001253', 'Направление', 'Смирнова Н.В.', 'Егоров Михаил Андреевич', 'ЭМК-00018447', '23.11.2026 10:47', 'Зарегистрирован', 0),
    _Doc('MED-001252', 'Справка', 'Орлова М.Д.', 'Жукова Ольга Николаевна', 'ЭМК-00018446', '23.11.2026 10:43', 'Ошибка обработки', 2),
    _Doc('MED-001250', 'Протокол лабораторного исследования', 'Петрова А.С.', 'Ильина Татьяна Сергеевна', 'ЭМК-00018444', '23.11.2026 10:34', 'Зарегистрирован', 0),
    _Doc('MED-001249', 'Выписной эпикриз', 'Кузнецова Е.В.', 'Крылов Артём Евгеньевич', 'ЭМК-00018443', '23.11.2026 10:29', 'Ожидает регистрации', 1),
    _Doc('MED-001245', 'Протокол осмотра', 'Иванов И.И.', 'Осипов Владимир Михайлович', 'ЭМК-00018439', '23.11.2026 10:02', 'Зарегистрирован', 0),
    for (var i = 0; i < 60; i++)
      _Doc('ARC-${(1001+i).toString().padLeft(6,'0')}',
        const ['Протокол осмотра','Протокол консультации','Лабораторное исследование','Выписной эпикриз'][i%4],
        const ['Иванов И.И.','Смирнова Н.В.','Петрова А.С.','Кузнецова Е.В.'][i%4],
        _patientFilterOptions[(i%(_patientFilterOptions.length-1))+1],
        'ЭМК-${(18433-i).toString().padLeft(8,'0')}',
        '21.11.2026 ${(8+i%12).toString().padLeft(2,'0')}:${(i*5%60).toString().padLeft(2,'0')}',
        const ['Зарегистрирован','Ожидает регистрации','Ошибка обработки'][i%3], i%3),

  ];

  static const files = [
    ('Исходный СЭМД', 'CDA / XML', Icons.code_outlined, 'document.xml'),
    ('PDF-представление', 'PDF', Icons.picture_as_pdf_outlined, 'document.pdf'),
    ('Подпись врача', 'CMS / P7S', Icons.verified_user_outlined, 'doctor.p7s'),
    ('Подпись медицинской организации', 'CMS / P7S', Icons.business_outlined, 'organization.p7s'),
    ('Оригинальный ответ N3', 'XML / JSON', Icons.data_object_outlined, 'n3_response.json'),
    ('Отчёт обработки', 'PDF', Icons.receipt_outlined, 'n3_response.pdf'),
    ('Протокол проверок', 'JSON', Icons.fact_check_outlined, 'validation.json'),
  ];

  @override
  Widget build(BuildContext context) {
    final doc = selectedDocument;
    return doc == null ? _buildList() : _buildDetails(doc);
  }

  Widget _buildList() {
    final filtered = documents.where((d) =>
      '${d.id} ${d.name} ${d.doctor} ${d.patient} ${d.emk}'.toLowerCase().contains(query.toLowerCase()) &&
      (patientFilter == 'Все пациенты' || d.patient == patientFilter)
    ).toList();
    return _PagePadding(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _PageHeading(title: 'Архив документов', subtitle: 'Список сформированных СЭМД и переход к карточке каждого документа'),
        const SizedBox(height: 20),
        const Wrap(spacing: 10, runSpacing: 10, children: [
          _MiniCount(label: 'Документов в архиве', value: '1 106'),
          _MiniCount(label: 'Зарегистрировано', value: '1 042'),
          _MiniCount(label: 'Требуют внимания', value: '64'),
        ]),
        const SizedBox(height: 16),
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск по ID, типу СЭМД, пациенту или врачу'),
            onChanged: (value) => setState(() => query = value),
          ),
        )),
        const SizedBox(height: 12),
        Card(child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 2),
            child: Align(
              alignment: Alignment.centerRight,
              child: _ColumnSettingsButton(
                screen: 'archive',
                options: columns,
                selected: visibleColumns,
                onChanged: (value) => setState(() => visibleColumns = value),
              ),
            ),
          ),
          _HorizontalTable(
            child: Column(children: [
              _columnHeaderRow(_orderedVisibleColumns(columns, visibleColumns), width: columns.where((c) => visibleColumns.contains(c.key)).length * 180.0),
              for (final d in filtered)
                InkWell(
                  onTap: () => setState(() => selectedDocument = d),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    child: _columnDataRow(
                      _orderedVisibleColumns(columns, visibleColumns),
                      {
                        ..._patientCells(_patientFieldValues(patientId: _patientIdFromEmk(d.emk), name: d.patient, emk: d.emk)),
                        'id': Text(d.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        'type': Text(d.name, style: const TextStyle(fontSize: 11)),
                        'patient': Text(d.patient, style: const TextStyle(fontSize: 10, color: Color(0xFF68798A))),
                        'emk': Text(d.emk, style: const TextStyle(fontSize: 10)),
                        'doctor': Text(d.doctor, style: const TextStyle(fontSize: 10)),
                        'date': Text(d.date, style: const TextStyle(fontSize: 10, color: Color(0xFF8794A3))),
                        'status': _StatusBadge(label: d.status, type: d.type),
                      },
                      width: 0, screen: 'archive',
                    ),
                  ),
                ),
              if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Text('Документы не найдены')),
            ]),
          ),
        ])),
        const SizedBox(height: 12),
        const Text('Записи и статусы демонстрационные. Выберите строку, чтобы открыть карточку документа.', style: TextStyle(fontSize: 10, color: Color(0xFF8996A4))),
      ]),
    );
  }

  Widget _buildDetails(_Doc doc) {
    return _PagePadding(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OutlinedButton.icon(
          onPressed: () => setState(() => selectedDocument = null),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('К списку документов'),
        ),
        const SizedBox(height: 18),
        _PageHeading(title: doc.id, subtitle: 'Карточка архивного СЭМД'),
        const SizedBox(height: 16),
        Card(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1B2D40))),
            const SizedBox(height: 12),
            Row(children: [_StatusBadge(label: doc.status, type: doc.type), const SizedBox(width: 8), const _DemoBadge()]),
            const Divider(height: 28),
            const _CardTitle(title: 'Сведения о документе', subtitle: 'Идентификация СЭМД и медицинской записи'),
            const SizedBox(height: 12),
            _InfoLine(label: 'ID документа', value: doc.id),
            _InfoLine(label: 'ФИО пациента', value: doc.patient),
            _InfoLine(label: 'ЭМК (номер)', value: doc.emk),
            _InfoLine(label: 'Лечащий врач', value: doc.doctor),
            _InfoLine(label: 'Дата формирования', value: doc.date),
            const Divider(height: 28),
            const _CardTitle(title: 'Файлы документа', subtitle: 'Состав архивного пакета'),
            const SizedBox(height: 8),
            for (final file in files)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFF0F5F9), borderRadius: BorderRadius.circular(9)), child: Icon(file.$3, color: const Color(0xFF47799E), size: 19)),
                title: Text(file.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                subtitle: Text('${file.$2} · ${file.$4}', style: const TextStyle(fontSize: 10)),
                trailing: IconButton(
                  tooltip: 'Просмотр файла',
                  onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
                    title: Text(file.$4),
                    content: const Text('Это макет архива. Физический файл пока не создан.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть'))],
                  )),
                  icon: const Icon(Icons.visibility_outlined, size: 19),
                ),
              ),
            const Divider(height: 24),
            const _CardTitle(title: 'Результаты проверок', subtitle: 'Демонстрационные статусы контроля'),
            const SizedBox(height: 12),
            const _CheckChip(label: 'ФРМО', detail: 'Проверено', ok: true),
            const SizedBox(height: 7),
            const _CheckChip(label: 'ФРМР', detail: 'Проверено', ok: true),
            const SizedBox(height: 7),
            const _CheckChip(label: 'УКЭП', detail: 'Проверено', ok: true),
            const SizedBox(height: 7),
            Row(children: [
              const Expanded(child: Text('Валидация N3', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              _StatusBadge(label: doc.type == 2 ? 'Не пройдена' : doc.type == 1 ? 'Есть замечания' : 'Пройдена', type: doc.type),
            ]),
          ]),
        )),
        const SizedBox(height: 12),
        const Text('Физические файлы и реальные результаты интеграционных проверок в прототипе отсутствуют.', style: TextStyle(fontSize: 10, color: Color(0xFF8996A4))),
      ]),
    );
  }
}


class _IemkPatient {
  final String id, name, birth, sex, policy, emk, address, phone;
  final int documents, alerts;
  const _IemkPatient(this.id, this.name, this.birth, this.sex, this.policy,
      this.emk, this.address, this.phone, this.documents, this.alerts);
}

class IemkPage extends StatefulWidget {
  const IemkPage({super.key});
  @override
  State<IemkPage> createState() => _IemkPageState();
}

class _IemkPageState extends State<IemkPage> {
  String query = '';
  _IemkPatient? selected;
  String section = 'Общие сведения';
  String typeFilter = 'Все типы';
  String periodFilter = 'За всё время';
  String? selectedDocumentId;
  bool refreshed = false;
  List<String> visibleColumns = _defaultColumns['iemk']!;
  // Метаданные PATIENTS: Field_Name / Field_Label / SQL_DATA_TYPE.
  static final columns = <_ColumnSpec>[..._patientColumns,
    const _ColumnSpec('DOCUMENTS', 'Документы ИЭМК · demo', 1),
    const _ColumnSpec('ALERTS', 'Замечания · demo', 1),
  ];

  @override
  void initState() {
    super.initState();
    _ColumnSettingsStore.get('iemk', columns).then((value) {
      if (mounted) setState(() => visibleColumns = value);
    });
  }

  static final patients = <_IemkPatient>[
    _IemkPatient('PAT-00018452', 'Алексеева Мария Викторовна', '14.06.1987', 'Женский', '4520 1845 2291 0048', 'ЭМК-00018452', 'г. Москва, ул. Новая, д. 18', '+7 (900) 123-45-67', 18, 1),
    _IemkPatient('PAT-00018449', 'Громов Дмитрий Олегович', '02.11.1975', 'Мужской', '4520 1844 9001 7732', 'ЭМК-00018449', 'г. Москва, ул. Садовая, д. 7', '+7 (900) 222-18-49', 12, 0),
    _IemkPatient('PAT-00018448', 'Демидова Наталья Игоревна', '23.03.1992', 'Женский', '4520 1844 8001 6521', 'ЭМК-00018448', 'г. Москва, пр-т Мира, д. 31', '+7 (900) 333-18-48', 9, 2),
    _IemkPatient('PAT-00018447', 'Егоров Михаил Андреевич', '09.09.1968', 'Мужской', '4520 1844 7001 4982', 'ЭМК-00018447', 'г. Москва, ул. Лесная, д. 4', '+7 (900) 444-18-47', 24, 0),
    _IemkPatient('PAT-00018446', 'Жукова Ольга Николаевна', '17.01.1981', 'Женский', '4520 1844 6001 3819', 'ЭМК-00018446', 'г. Москва, ул. Полевая, д. 12', '+7 (900) 555-18-46', 7, 1),    for (var i = 0; i < 60; i++)
      _IemkPatient('PAT-TEST-${(i+1).toString().padLeft(4,'0')}',
        _patientFilterOptions[(i%(_patientFilterOptions.length-1))+1],
        '${(i%28+1).toString().padLeft(2,'0')}.${(i%12+1).toString().padLeft(2,'0')}.${1960+i%40}',
        i.isEven ? 'Женский' : 'Мужской',
        '4520 ${1800+i} ${1000+i} ${7000+i}',
        'ЭМК-${(18300-i).toString().padLeft(8,'0')}',
        'г. Москва, ул. Тестовая, д. ${i+1}',
        '+7 (900) ${100+i}-18-${(10+i%90).toString().padLeft(2,'0')}',
        3+i%28, i%4==0 ? 2 : i%3),

  ];

  static const history = [
    ('23.11.2026 11:18', 'Протокол консультации', 'Кардиолог', 'Зарегистрирован', 0, 'MED-001258'),
    ('18.11.2026 09:42', 'Протокол лабораторного исследования', 'КДЛ', 'Зарегистрирован', 0, 'MED-001190'),
    ('12.11.2026 14:05', 'Протокол осмотра', 'Терапевт', 'Зарегистрирован', 0, 'MED-001142'),
    ('04.11.2026 10:30', 'Направление', 'Терапевт', 'Ожидает регистрации', 1, 'MED-001081'),
    ('21.10.2026 12:16', 'Протокол инструментального исследования', 'Функциональная диагностика', 'Зарегистрирован', 0, 'MED-000974'),
  ];

  @override
  Widget build(BuildContext context) {
    if (selectedDocumentId != null) return _documentDetails();
    return selected == null ? _listView() : _patientView(selected!);
  }

  Widget _listView() {
    final filtered = patients.where((p) =>
      (p.name + p.id + p.emk + p.policy).toLowerCase().contains(query.toLowerCase())).toList();
    return _PagePadding(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _PageHeading(title: 'Индивидуальная электронная медицинская карта',
        subtitle: 'Поиск пациентов, просмотр медицинской истории и контроль документов ИЭМК',
        trailing: _DemoBadge()),
      const SizedBox(height: 20),
      const Wrap(spacing: 10, runSpacing: 10, children: [
        _MiniCount(label: 'Пациентов в реестре', value: '8 426'),
        _MiniCount(label: 'ИЭМК с документами', value: '7 918'),
        _MiniCount(label: 'Требуют внимания', value: '126'),
      ]),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: TextField(
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
          hintText: 'Поиск по ФИО, ID пациента, номеру ИЭМК или полису ОМС'),
        onChanged: (v) => setState(() => query = v),
      ))),
      const SizedBox(height: 12),
      Card(child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 2),
          child: Align(
            alignment: Alignment.centerRight,
            child: _ColumnSettingsButton(
              screen: 'iemk',
              options: columns,
              selected: visibleColumns,
              onChanged: (value) => setState(() => visibleColumns = value),
            ),
          ),
        ),
        _HorizontalTable(
            child: Column(children: [
            _columnHeaderRow(_orderedVisibleColumns(columns, visibleColumns), width: columns.where((c) => visibleColumns.contains(c.key)).length * 180.0),
            for (final p in filtered)
              InkWell(
                onTap: () => setState(() { selected = p; section = 'Общие сведения'; }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                  child: _columnDataRow(
                    _orderedVisibleColumns(columns, visibleColumns),
                    {
                      ..._patientCells(_patientFieldValues(patientId: p.id, name: p.name, emk: p.emk, birth: p.birth, sex: p.sex, policy: p.policy, address: p.address, phone: p.phone)),
                      'FIO': Text(p.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      'NOM': Text(p.name.split(' ').first, style: const TextStyle(fontSize: 10)),
                      'PRENOM': Text(p.name.split(' ').length > 1 ? p.name.split(' ')[1] : '—', style: const TextStyle(fontSize: 10)),
                      'PATRONYME': Text(p.name.split(' ').length > 2 ? p.name.split(' ').skip(2).join(' ') : '—', style: const TextStyle(fontSize: 10)),
                      'N_OMON': Text(p.emk, style: const TextStyle(fontSize: 10)),
                      'NOMER_MEDICISKOJ_KART': const Text('—', style: TextStyle(fontSize: 10)),
                      'NE_LE': Text(p.birth, style: const TextStyle(fontSize: 10, color: Color(0xFF718095))),
                      'POL': Text(p.sex, style: const TextStyle(fontSize: 10)),
                      'NOMER_POMS': Text(p.policy, style: const TextStyle(fontSize: 10)),
                      'SERIQ_POMS': const Text('—', style: TextStyle(fontSize: 10)),
                      'MOBIL_TELEFON': Text(p.phone, style: const TextStyle(fontSize: 10)),
                      'TEL': Text(p.phone, style: const TextStyle(fontSize: 10)),
                      'EMAIL': const Text('—', style: TextStyle(fontSize: 10)),
                      'SNILS': const Text('—', style: TextStyle(fontSize: 10)),
                      'ADRES_PO_PROPISKE': Text(p.address, style: const TextStyle(fontSize: 10)),
                      'ADRES_FAKTIHESKIJ': const Text('—', style: TextStyle(fontSize: 10)),
                      'ARCHIVE': const Text('Нет', style: TextStyle(fontSize: 10)),
                      'DMS': const Text('—', style: TextStyle(fontSize: 10)),
                      'OMS': const Text('Да', style: TextStyle(fontSize: 10)),
                      'INVALIDNOST': const Text('—', style: TextStyle(fontSize: 10)),
                      'DISPANSERNAQ_GRUPPA': const Text('—', style: TextStyle(fontSize: 10)),
                      'DATA_POSTANOVKI_NA_UHET': const Text('—', style: TextStyle(fontSize: 10)),
                      'NASELENN_J_PUNKT': const Text('Москва', style: TextStyle(fontSize: 10)),
                      'DOCUMENTS': Text(p.documents.toString(), style: const TextStyle(fontSize: 11)),
                      'ALERTS': p.alerts == 0
                          ? const _StatusBadge(label: 'Нет', type: 0)
                          : _StatusBadge(label: p.alerts.toString(), type: 1),
                    },
                    width: 0, screen: 'iemk',
                  ),
                ),
              ),
            if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Text('Пациенты не найдены')),
          ]),
        ),
      ])),
      const SizedBox(height: 12),
      const Text('Используются вымышленные демонстрационные данные. Поиск не обращается к Медиалог 7 или ЕГИСЗ.',
        style: TextStyle(fontSize: 10, color: Color(0xFF8996A4))),
    ]));
  }

  Widget _patientView(_IemkPatient p) {
    const tabs = ['Общие сведения', 'Медицинская история', 'Документы СЭМД', 'Направления', 'Сопоставление'];
    return _PagePadding(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      OutlinedButton.icon(onPressed: () => setState(() { selected = null; selectedDocumentId = null; }),
        icon: const Icon(Icons.arrow_back, size: 16), label: const Text('К списку пациентов')),
      const SizedBox(height: 16),
      _PageHeading(title: p.name, subtitle: 'Индивидуальная электронная медицинская карта · ${p.emk}',
        trailing: Wrap(spacing: 8, children: [const _DemoBadge(), OutlinedButton.icon(
          onPressed: _refreshDemo, icon: const Icon(Icons.refresh, size: 15), label: const Text('Обновить'))])),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Wrap(spacing: 24, runSpacing: 14, children: [
        _PatientSummary(label: 'ID пациента', value: p.id),
        _PatientSummary(label: 'Дата рождения', value: p.birth),
        _PatientSummary(label: 'Пол', value: p.sex),
        _PatientSummary(label: 'Документов в ИЭМК', value: p.documents.toString()),
        _PatientSummary(label: 'Замечаний', value: p.alerts.toString()),
      ]))),
      const SizedBox(height: 14),
      Card(child: Padding(padding: const EdgeInsets.all(8), child: Wrap(spacing: 6, runSpacing: 6,
        children: [for (final t in tabs) ChoiceChip(label: Text(t, style: const TextStyle(fontSize: 11)),
          selected: section == t, onSelected: (_) => setState(() => section = t))]))),
      const SizedBox(height: 14),
      if (section == 'Общие сведения') _generalInfo(p)
      else if (section == 'Медицинская история') _historyView()
      else if (section == 'Документы СЭМД') _historyView(onlyDocuments: true)
      else if (section == 'Направления') _referralsView()
      else _matchingView(p),
      const SizedBox(height: 12),
      Text(refreshed ? 'Демо-обновление выполнено. Подключение к ЕГИСЗ не выполнялось.' :
        'Карточка ИЭМК демонстрационная. Данные не получены из ЕГИСЗ.',
        style: const TextStyle(fontSize: 10, color: Color(0xFF8996A4))),
    ]));
  }

  Widget _generalInfo(_IemkPatient p) => Card(child: Padding(padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _CardTitle(title: 'Идентификационные сведения', subtitle: 'Демонстрационная карточка пациента'),
      const SizedBox(height: 12),
      _InfoLine(label: 'ФИО', value: p.name),
      _InfoLine(label: 'Дата рождения', value: p.birth),
      _InfoLine(label: 'Пол', value: p.sex),
      _InfoLine(label: 'Полис ОМС', value: p.policy),
      _InfoLine(label: 'Номер ИЭМК', value: p.emk),
      _InfoLine(label: 'Адрес', value: p.address),
      _InfoLine(label: 'Телефон', value: p.phone),
      const Divider(height: 26),
      const _CardTitle(title: 'Состояние ИЭМК', subtitle: 'Сводка по документам и синхронизации'),
      const SizedBox(height: 12),
      const _CheckChip(label: 'Идентификация пациента', detail: 'Подтверждена (DEMO)', ok: true),
      const SizedBox(height: 8),
      const _CheckChip(label: 'Связь с Медиалог 7', detail: 'Локальная запись', ok: true),
      const SizedBox(height: 8),
      const _CheckChip(label: 'Синхронизация с ЕГИСЗ', detail: 'Не выполнялась', ok: false),
    ])));

  void _refreshDemo() {
    setState(() => refreshed = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Демо-обновление завершено. Реальные источники не подключены.')));
  }

  Widget _historyView({bool onlyDocuments = false}) {
    final items = history.where((e) {
      final referral = e.$2 == 'Направление';
      final typeOk = typeFilter == 'Все типы' ||
        (typeFilter == 'Направления' ? referral : !referral);
      final periodOk = periodFilter == 'За всё время' ||
        (periodFilter == 'Ноябрь 2026' ? e.$1.contains('.11.2026') : e.$1.contains('.10.2026'));
      return typeOk && periodOk && (!onlyDocuments || !referral);
    }).toList();
    return Card(child: Column(children: [
      Padding(padding: const EdgeInsets.all(18), child: _CardTitle(
        title: onlyDocuments ? 'Документы СЭМД' : 'Медицинская история',
        subtitle: 'Хронология медицинских событий и результатов обработки')),
      const Divider(height: 1),
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Wrap(spacing: 10, runSpacing: 8, children: [
        SizedBox(width: 180, child: DropdownButtonFormField<String>(initialValue: periodFilter,
          decoration: const InputDecoration(labelText: 'Период'),
          items: const ['За всё время', 'Ноябрь 2026', 'Октябрь 2026'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => periodFilter = v ?? 'За всё время'))),
        SizedBox(width: 190, child: DropdownButtonFormField<String>(initialValue: typeFilter,
          decoration: const InputDecoration(labelText: 'Тип записи'),
          items: const ['Все типы', 'Протокол', 'Направления'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => typeFilter = v ?? 'Все типы'))),
        TextButton.icon(onPressed: () => setState(() { periodFilter = 'За всё время'; typeFilter = 'Все типы'; }),
          icon: const Icon(Icons.filter_alt_off, size: 16), label: const Text('Сбросить')),
      ])),
      if (items.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('По выбранным фильтрам записей нет')),
      for (final e in items)
        ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          leading: const CircleAvatar(backgroundColor: Color(0xFFEAF2F8),
            child: Icon(Icons.description_outlined, color: Color(0xFF47799E), size: 18)),
          title: Text(e.$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          subtitle: Text('${e.$1} · ${e.$3} · ${e.$6}', style: const TextStyle(fontSize: 10)),
          trailing: _StatusBadge(label: e.$4, type: e.$5),
          onTap: () => setState(() => selectedDocumentId = e.$6),
        ),
    ]));
  }

  Widget _documentDetails() {
    final e = history.firstWhere((item) => item.$6 == selectedDocumentId);
    return _PagePadding(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      OutlinedButton.icon(onPressed: () => setState(() => selectedDocumentId = null),
        icon: const Icon(Icons.arrow_back, size: 16), label: const Text('К медицинской карте')),
      const SizedBox(height: 16),
      _PageHeading(title: e.$6, subtitle: 'Карточка документа в составе ИЭМК', trailing: const _DemoBadge()),
      const SizedBox(height: 14),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(e.$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _StatusBadge(label: e.$4, type: e.$5),
        const Divider(height: 24),
        _InfoLine(label: 'Дата', value: e.$1),
        _InfoLine(label: 'Подразделение / специалист', value: e.$3),
        _InfoLine(label: 'ID локальной записи', value: e.$6),
        const Divider(height: 24),
        const _CardTitle(title: 'Содержание документа', subtitle: 'Демонстрационное представление'),
        const SizedBox(height: 10),
        const SelectableText('Медицинская запись содержит сведения о проведённом приёме или исследовании. Подробное структурированное содержание будет отображаться после подключения источника данных.',
          style: TextStyle(fontSize: 12, height: 1.5)),
        const Divider(height: 24),
        const _CardTitle(title: 'Состав пакета', subtitle: 'Предполагаемые представления документа'),
        const ListTile(leading: Icon(Icons.code), title: Text('CDA / XML', style: TextStyle(fontSize: 11)), subtitle: Text('Структурированный документ', style: TextStyle(fontSize: 10))),
        const ListTile(leading: Icon(Icons.picture_as_pdf_outlined), title: Text('PDF-представление', style: TextStyle(fontSize: 11)), subtitle: Text('Человекочитаемая версия', style: TextStyle(fontSize: 10))),
        const Text('Оригинальные файлы не загружены. Это демонстрационная карточка, не медицинский документ.',
          style: TextStyle(fontSize: 10, color: Color(0xFF8996A4))),
      ]))),
    ]));
  }

  Widget _matchingView(_IemkPatient p) => Column(children: [
    Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _CardTitle(title: 'Сопоставление записей', subtitle: 'Связь локальных данных Медиалог 7 с документами ИЭМК'),
      const SizedBox(height: 12),
      _InfoLine(label: 'Локальная запись', value: 'MED-001258'),
      _InfoLine(label: 'Идентификатор пациента', value: p.id),
      _InfoLine(label: 'Номер ИЭМК', value: p.emk),
      const Divider(height: 24),
      const _CheckChip(label: 'ФИО и дата рождения', detail: 'Совпадают в демо-записях', ok: true),
      const SizedBox(height: 8),
      const _CheckChip(label: 'Локальная запись Медиалог', detail: 'Найдена', ok: true),
      const SizedBox(height: 8),
      const _CheckChip(label: 'Внешний ID ЕГИСЗ', detail: 'Требует подтверждения', ok: false),
    ]))),
    const SizedBox(height: 12),
    Card(child: Column(children: [
      const ListTile(title: Text('Контроль расхождений', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        subtitle: Text('Сопоставление идентификаторов и атрибутов пациента', style: TextStyle(fontSize: 10))),
      const Divider(height: 1),
      const ListTile(leading: Icon(Icons.check_circle_outline, color: Color(0xFF269B77)),
        title: Text('ФИО и дата рождения', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        subtitle: Text('Совпадение демонстрационных данных', style: TextStyle(fontSize: 10))),
      const ListTile(leading: Icon(Icons.warning_amber_rounded, color: Color(0xFFD99A2B)),
        title: Text('Внешний идентификатор пациента', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        subtitle: Text('Нужна проверка соответствия при подключении N3.Health', style: TextStyle(fontSize: 10))),
    ])),
    const SizedBox(height: 10),
    Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Демо-проверка выполнена. Реальные источники не подключены.'))),
      icon: const Icon(Icons.compare_arrows, size: 16), label: const Text('Проверить сопоставление'))),
  ]);

  Widget _referralsView() => Card(child: Padding(padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _CardTitle(title: 'Направления', subtitle: 'Направления на консультации и исследования'),
      const SizedBox(height: 14),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.assignment_outlined, color: Color(0xFF47799E)),
        title: Text('Направление на консультацию кардиолога', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        subtitle: Text('04.11.2026 · Ожидает регистрации', style: TextStyle(fontSize: 10))),
      const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.assignment_outlined, color: Color(0xFF47799E)),
        title: Text('Направление на лабораторное исследование', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        subtitle: Text('18.10.2026 · Зарегистрировано', style: TextStyle(fontSize: 10))),
    ])));
}

class _PatientSummary extends StatelessWidget {
  final String label, value;
  const _PatientSummary({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => SizedBox(width: 145, child: Column(crossAxisAlignment: CrossAxisAlignment.start,
    children: [Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF8190A0))),
      const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]));
}


String _auditPatientName(String objectId) {
  const links = <String, String>{
    'MED-001258':'Алексеева Мария Викторовна',
    'MED-001257':'Белов Андрей Сергеевич',
    'MED-001256':'Васильева Елена Павловна',
    'MED-001255':'Громов Дмитрий Олегович',
    'MED-001254':'Демидова Наталья Игоревна',
    'MED-001253':'Егоров Михаил Андреевич',
    'MED-001252':'Жукова Ольга Николаевна',
    'MED-001251':'Зайцев Павел Владимирович',
    'MED-001250':'Ильина Татьяна Сергеевна',
    'MED-001249':'Крылов Артём Евгеньевич',
    'MED-001248':'Лебедева Анна Дмитриевна',
    'MED-001247':'Макаров Сергей Петрович',
    'MED-001246':'Никитина Ирина Алексеевна',
    'MED-001245':'Осипов Владимир Михайлович',
    'MED-001244':'Павлова Светлана Романовна',
    'MED-001243':'Романов Кирилл Денисович',
    'MED-001242':'Соколова Марина Юрьевна',
    'MED-001241':'Тихонов Алексей Борисович',
    'MED-001240':'Фёдорова Дарья Константиновна',
    'BATCH-00034':'Алексеева Мария Викторовна',
    'TPL-00008':'Васильева Елена Павловна',
  };
  return links[objectId] ?? '—';
}

Map<String, String> _auditPatientValues(String objectId) {
  final name = _auditPatientName(objectId);
  if (name == '—') return {};
  const emks = <String, String>{
    'Алексеева Мария Викторовна':'ЭМК-00018452',
    'Белов Андрей Сергеевич':'ЭМК-00018451',
    'Васильева Елена Павловна':'ЭМК-00018450',
    'Громов Дмитрий Олегович':'ЭМК-00018449',
    'Демидова Наталья Игоревна':'ЭМК-00018448',
    'Егоров Михаил Андреевич':'ЭМК-00018447',
    'Жукова Ольга Николаевна':'ЭМК-00018446',
    'Зайцев Павел Владимирович':'ЭМК-00018445',
    'Ильина Татьяна Сергеевна':'ЭМК-00018444',
    'Крылов Артём Евгеньевич':'ЭМК-00018443',
    'Лебедева Анна Дмитриевна':'ЭМК-00018442',
    'Макаров Сергей Петрович':'ЭМК-00018441',
    'Никитина Ирина Алексеевна':'ЭМК-00018440',
    'Осипов Владимир Михайлович':'ЭМК-00018439',
    'Павлова Светлана Романовна':'ЭМК-00018438',
    'Романов Кирилл Денисович':'ЭМК-00018437',
    'Соколова Марина Юрьевна':'ЭМК-00018436',
    'Тихонов Алексей Борисович':'ЭМК-00018435',
    'Фёдорова Дарья Константиновна':'ЭМК-00018434',
  };
  return _patientFieldValues(patientId: _patientIdFromEmk(emks[name]!), name: name, emk: emks[name]!);
}

class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  String query = '';
  String patientFilter = 'Все пациенты';
  List<String> visibleColumns = _defaultColumns['audit']!;
  static final columns = <_ColumnSpec>[..._patientColumns,
    const _ColumnSpec('time', 'Время', 2),
    const _ColumnSpec('event', 'Событие', 4),
    const _ColumnSpec('object', 'Объект', 2),
    const _ColumnSpec('user', 'Пользователь', 2),
    const _ColumnSpec('result', 'Результат', 2),
  ];

  @override
  void initState() {
    super.initState();
    _ColumnSettingsStore.get('audit', columns).then((value) {
      if (mounted) setState(() => visibleColumns = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final events = [
      ('11:18:42', 'Формирование СЭМД', 'MED-001258', 'Успешно', 0, 'Оператор'),
      ('11:18:31', 'Проверка ФРМР', 'MED-001258', 'Успешно', 0, 'Система'),
      ('11:17:58', 'Проверка сертификата врача', 'MED-001258', 'Успешно', 0, 'Система'),
      ('11:12:16', 'Постановка в очередь', 'MED-001257', 'Ожидание', 1, 'Система'),
      ('11:10:04', 'Валидация CDA', 'MED-001256', 'Ошибка', 2, 'Система'),
      ('11:05:22', 'Формирование СЭМД', 'MED-001256', 'Успешно', 0, 'Оператор'),
      ('10:58:47', 'Предварительный контроль', 'BATCH-00034', 'Успешно', 0, 'Оператор'),
      ('10:54:13', 'Проверка УКЭП организации', 'MED-001254', 'Требует внимания', 1, 'Система'),
      ('10:47:09', 'Отправка СЭМД', 'MED-001253', 'Успешно', 0, 'Оператор'),
      ('10:43:51', 'Проверка ФРМО', 'MED-001252', 'Успешно', 0, 'Система'),
      ('10:41:26', 'Проверка УКЭП врача', 'MED-001252', 'Ошибка', 2, 'Система'),
      ('10:35:02', 'Обновление шаблона СЭМД', 'TPL-00008', 'Изменено', 1, 'Администратор'),
      for (var i = 0; i < 88; i++)
        ('${(9+i%3).toString().padLeft(2,'0')}:${(i*7%60).toString().padLeft(2,'0')}:${(i*11%60).toString().padLeft(2,'0')}',
          const ['Формирование СЭМД','Проверка ФРМО','Проверка ФРМР','Валидация CDA','Постановка в очередь'][i%5],
          'MED-${(1258-i%19).toString().padLeft(6,'0')}',
          const ['Успешно','Ожидание','Ошибка'][i%3], i%3,
          const ['Оператор','Система','Администратор'][i%3]),

    ];
    return _PagePadding(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _PageHeading(title: 'Журнал действий', subtitle: 'Аудит операций пользователей и системных процессов'),
        const SizedBox(height: 20),
        const Wrap(spacing: 10, runSpacing: 10, children: [
          _MiniCount(label: 'Событий сегодня', value: '284'),
          _MiniCount(label: 'Успешно', value: '261'),
          _MiniCount(label: 'Ошибки', value: '12'),
          _MiniCount(label: 'Предупреждения', value: '11'),
        ]),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск по событию, пользователю или ID'),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 10),
          _patientFilter(patientFilter, (value) => setState(() => patientFilter = value)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: _ColumnSettingsButton(
              screen: 'audit',
              options: columns,
              selected: visibleColumns,
              onChanged: (value) => setState(() => visibleColumns = value),
            ),
          ),
          const Divider(height: 8),
          _HorizontalTable(
            child: Column(children: [
              _columnHeaderRow(_orderedVisibleColumns(columns, visibleColumns), width: columns.where((c) => visibleColumns.contains(c.key)).length * 180.0),
              for (final e in events.where((e) =>
                (e.$1 + ' ' + e.$2 + ' ' + e.$3 + ' ' + e.$4 + ' ' + e.$6 + ' ' + _auditPatientName(e.$3)).toLowerCase().contains(query.toLowerCase()) &&
                (patientFilter == 'Все пациенты' || _auditPatientName(e.$3) == patientFilter)))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: _columnDataRow(
                    _orderedVisibleColumns(columns, visibleColumns),
                    {
                      ..._patientCells(_auditPatientValues(e.$3)),
                      'time': Text(e.$1, style: const TextStyle(fontSize: 10, color: Color(0xFF77889A))),
                      'event': Text(e.$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      'object': Text(e.$3, style: const TextStyle(fontSize: 10)),
                      'user': Text(e.$6, style: const TextStyle(fontSize: 10, color: Color(0xFF77889A))),
                      'result': _StatusBadge(label: e.$4, type: e.$5),
                    },
                    width: 0, screen: 'audit',
                  ),
                ),
            ]),
          ),
        ]))),
        const SizedBox(height: 10),
        const Text('Журнал демонстрационный. Персональные данные и содержимое медицинских документов в технический лог не выводятся.', style: TextStyle(fontSize: 10, color: Color(0xFF8996A4))),
      ]),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const sections = [
      ('Медиалог 7', 'Источник данных и параметры подключения к MS SQL Server', Icons.storage_outlined),
      ('N3.Health', 'Адреса сервисов, SOAP / REST, идентификаторы интеграции', Icons.hub_outlined),
      ('Криптография', 'CryptoPro CSP, сертификаты врача и медицинской организации', Icons.enhanced_encryption_outlined),
      ('Медицинская организация', 'Реквизиты МО, OID, сведения ФРМО', Icons.apartment_outlined),
      ('Формирование СЭМД', 'Шаблоны CDA, версии документов и правила заполнения', Icons.description_outlined),
      ('Архив и резервное копирование', 'Каталоги хранения, контроль целостности и резервные копии', Icons.backup_outlined),
      ('Автоматизация', 'Расписание, режим отправки и правила повторных попыток', Icons.schedule_outlined),
    ];
    return _PagePadding(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _PageHeading(title: 'Настройки', subtitle: 'Конфигурация будущих интеграционных компонентов'),
        const SizedBox(height: 20),
        for (final s in sections)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFF0F5F9), borderRadius: BorderRadius.circular(11)), child: Icon(s.$3, color: const Color(0xFF47799E))),
              title: Text(s.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(s.$2, style: const TextStyle(fontSize: 10, color: Color(0xFF7C8B9A)))),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF8996A4)),
              onTap: () => showDialog(context: context, builder: (_) => AlertDialog(title: Text(s.$1), content: const Text('Раздел будет реализован после утверждения визуального прототипа. Сейчас интеграции отключены.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно'))])),
            ),
          ),
        const SizedBox(height: 12),
        const _CheckChip(label: 'Режим приложения', detail: 'Только демонстрация', ok: false),
      ]),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label, value;
  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 150, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF7C8B9A)))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
    ]),
  );
}