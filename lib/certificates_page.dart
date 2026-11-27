import 'package:material_ui/material_ui.dart';

/// Демонстрационный реестр сертификатов. Windows Certificate Store и
/// криптопровайдеры не опрашиваются, закрытые ключи не читаются.
class CertificatesPage extends StatefulWidget {
  const CertificatesPage({super.key});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  late final List<_Certificate> _items;
  final _search = TextEditingController();
  final _scrollController = ScrollController();
  String _status = 'Все статусы';
  String _type = 'Все типы';
  DateTime _checkedAt = DateTime.now();
  final List<String> _columnOrder = ['owner', 'type', 'issuer', 'validTo', 'remaining', 'state', 'registration'];
  final Map<String, double> _columnWidths = {
    'owner': 220,
    'type': 190,
    'issuer': 220,
    'validTo': 145,
    'remaining': 155,
    'state': 150,
    'registration': 170,
  };
  static const Map<String, String> _columnLabels = {
    'owner': 'Владелец',
    'type': 'Тип сертификата',
    'issuer': 'Удостоверяющий центр',
    'validTo': 'Действителен до',
    'remaining': 'Осталось',
    'state': 'Статус',
    'registration': 'Регистрация',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _items = [
      _Certificate('CERT-0001', 'Иванов Иван Иванович', 'Врач-терапевт', 'УКЭП врача', 'УЦ АО «Такском»', '04A8 7F21 9C30 11D2', 'A8F3 71C2 90BD 4E11 7A62 09CC 18D0 5A31', 'HDIMAGE\\IvanovContainer', now.subtract(const Duration(days: 55)), now.add(const Duration(days: 310)), true),
      _Certificate('CERT-0002', 'Сидорова Анна Викторовна', 'Врач-кардиолог', 'УКЭП врача', 'УЦ ООО «Калуга Астрал»', '03D1 44A9 82B0 7C10', '5D19 0A7E 3F42 C8B1 6E90 4A11 29BC 70D3', 'HDIMAGE\\SidorovaContainer', now.subtract(const Duration(days: 345)), now.add(const Duration(days: 18)), true),
      _Certificate('CERT-0003', 'ГБУЗ «Городская поликлиника № 12»', 'Медицинская организация', 'УКЭП медицинской организации', 'УЦ ФКУ «Налог-Сервис» ФНС России', '71C0 2E19 A4B5 8D60', '91B2 6E44 7A03 C8F1 0D55 9A2B 6C31 E870', 'Windows\\MY', now.subtract(const Duration(days: 120)), now.add(const Duration(days: 9)), true),
      _Certificate('CERT-0004', 'Смирнов Алексей Олегович', 'Врач-рентгенолог', 'УКЭП врача', 'УЦ ООО «Калуга Астрал»', 'A012 8D77 3F91 44C2', 'C2B7 11F9 40D3 8A62 19EF 3C20 8B11 0A5D', 'HDIMAGE\\SmirnovContainer', now.subtract(const Duration(days: 35)), now.add(const Duration(days: 330)), false),
      _Certificate('CERT-0005', 'Петров Пётр Сергеевич', 'Врач-хирург', 'УКЭП врача', 'УЦ АО «Такском»', '8B71 2F09 5A34 C611', '2A71 C0F9 5D34 B811 9A62 41EF 7C30 D509', 'Не определён', now.subtract(const Duration(days: 420)), now.subtract(const Duration(days: 12)), true),
      _Certificate('CERT-0006', 'Медицинская информационная система', 'Системная интеграция', 'Служебный сертификат', 'Тестовый удостоверяющий центр', 'DEMO 2026 0019', 'DEMO 7C11 A290 45F0 0000 0000 0000 0006', 'Локальное хранилище (демо)', now.subtract(const Duration(days: 20)), now.add(const Duration(days: 540)), true),
      _Certificate('CERT-0007', 'Орлов Николай Сергеевич', 'Врач-невролог', 'УКЭП врача', 'Тестовый удостоверяющий центр', 'DEMO REVOKED 2026', 'DEMO 0000 0000 0000 0000 0000 0000 0007', 'Не определён', now.subtract(const Duration(days: 90)), now.add(const Duration(days: 275)), true, revoked: true),
    ];
  }

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<_Certificate> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _items.where((c) {
      final haystack = [c.owner, c.position, c.issuer, c.serial, c.thumbprint, c.container].join(' ').toLowerCase();
      return (q.isEmpty || haystack.contains(q)) &&
          (_status == 'Все статусы' || c.state.label == _status) &&
          (_type == 'Все типы' || c.type == _type);
    }).toList();
  }

  int _count(_CertificateState s) => _items.where((c) => c.state == s).length;

  @override
  Widget build(BuildContext context) {
    final active = _count(_CertificateState.active);
    final expiring = _count(_CertificateState.expiring);
    final expired = _count(_CertificateState.expired);
    final pending = _count(_CertificateState.pending);
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _header(context),
              const SizedBox(height: 20),
              LayoutBuilder(builder: (context, c) {
                final w = (c.maxWidth - 36) / 4;
                return Wrap(spacing: 12, runSpacing: 12, children: [
                  _Metric(w, 'Действуют', '$active', 'Срок более 30 дней', const Color(0xFF23845B), Icons.verified_outlined),
                  _Metric(w, 'Истекают', '$expiring', 'Осталось не более 30 дней', const Color(0xFFD18A19), Icons.schedule_outlined),
                  _Metric(w, 'Истекли', '$expired', 'Требуется перевыпуск', const Color(0xFFC44545), Icons.gpp_bad_outlined),
                  _Metric(w, 'Не зарегистрированы', '$pending', 'Нужна проверка привязки', const Color(0xFF477AA5), Icons.pending_actions_outlined),
                ]);
              }),
              const SizedBox(height: 18),
              if (expired > 0 || expiring > 0) ...[
                _ExpiryAlert(expired: expired, expiring: expiring),
                const SizedBox(height: 18),
              ],
              _registry(),
              const SizedBox(height: 18),
              _securityInfo(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Wrap(
    spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Управление ЭЦП и сертификатами', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF1B2D40))),
        SizedBox(height: 5),
        Text('Реестр сертификатов сотрудников и медицинской организации, контроль сроков действия', style: TextStyle(fontSize: 12, color: Color(0xFF748396))),
      ]),
      OutlinedButton.icon(onPressed: _showImportInfo, icon: const Icon(Icons.add_circle_outline, size: 18), label: const Text('Добавить сертификат')),
      FilledButton.icon(onPressed: () {
        setState(() => _checkedAt = DateTime.now());
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Демонстрационные сроки пересчитаны. Хранилища сертификатов не опрашивались.')));
      }, icon: const Icon(Icons.fact_check_outlined, size: 18), label: const Text('Проверить сроки')),
    ],
  );

  Widget _registry() {
    final rows = _filtered;
    return Card(child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Реестр сертификатов', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('Выберите запись, чтобы открыть карточку сертификата', style: TextStyle(fontSize: 11, color: Color(0xFF7B8998))),
          ])),
          Text('${rows.length} из ${_items.length}', style: const TextStyle(fontSize: 11, color: Color(0xFF718096), fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final compact = c.maxWidth < 760;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            SizedBox(width: compact ? c.maxWidth : 330, child: TextField(
              controller: _search, onChanged: (_) => setState(() {}),
              decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search, size: 19), hintText: 'Поиск по владельцу, номеру, УЦ',
                suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close, size: 17))),
            )),
            SizedBox(width: compact ? c.maxWidth : 210, child: DropdownButtonFormField<String>(
              initialValue: _status, isExpanded: true, decoration: const InputDecoration(isDense: true, labelText: 'Статус'),
              items: ['Все статусы', ..._CertificateState.values.map((e) => e.label)].map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => _status = v ?? 'Все статусы'),
            )),
            SizedBox(width: compact ? c.maxWidth : 250, child: DropdownButtonFormField<String>(
              initialValue: _type, isExpanded: true, decoration: const InputDecoration(isDense: true, labelText: 'Тип сертификата'),
              items: ['Все типы', 'УКЭП врача', 'УКЭП медицинской организации', 'Служебный сертификат'].map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => _type = v ?? 'Все типы'),
            )),
          ]);
        }),
        const SizedBox(height: 12),
        const Divider(height: 1),
        if (rows.isEmpty)
          const Padding(padding: EdgeInsets.all(28), child: Center(child: Column(children: [
            Icon(Icons.search_off, size: 34, color: Color(0xFF98A2B3)),
            SizedBox(height: 8),
            Text('Сертификаты не найдены', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Измените запрос или параметры фильтрации', style: TextStyle(fontSize: 11, color: Color(0xFF7B8998))),
          ])))
        else
          _certificateTable(rows),
        SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFF8190A0)),
          const SizedBox(width: 6),
          const Expanded(child: Text('Нажмите на строку, чтобы посмотреть сведения о сертификате', style: TextStyle(fontSize: 10, color: Color(0xFF8190A0)))),
          Text('Последняя проверка: ${_dateTime(_checkedAt)}', style: const TextStyle(fontSize: 10, color: Color(0xFF8190A0))),
        ]),
      ]),
    ));
  }

  double get _tableWidth =>
      _columnOrder.fold(0.0, (total, key) => total + (_columnWidths[key] ?? 160));

  Widget _certificateTable(List<_Certificate> rows) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: _tableWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 50,
            child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final key = _columnOrder.removeAt(oldIndex);
                  _columnOrder.insert(newIndex, key);
                });
              },
              children: [
                for (var index = 0; index < _columnOrder.length; index++)
                  SizedBox(
                    key: ValueKey(_columnOrder[index]),
                    width: _columnWidths[_columnOrder[index]],
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Tooltip(
                            message: 'Перетащите, чтобы изменить порядок колонки',
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 12, 16, 10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _columnLabels[_columnOrder[index]]!.toUpperCase(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF52677D),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 5,
                          bottom: 5,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeColumn,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragUpdate: (details) {
                                setState(() {
                                  final key = _columnOrder[index];
                                  _columnWidths[key] = ((_columnWidths[key] ?? 160) +
                                          details.delta.dx)
                                      .clamp(100.0, 420.0)
                                      .toDouble();
                                });
                              },
                              child: const SizedBox(
                                width: 10,
                                child: Center(
                                  child: VerticalDivider(
                                    width: 1,
                                    thickness: 1,
                                    color: Color(0xFFB8C5D1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final certificate in rows)
            InkWell(
              onTap: () => _showDetails(certificate),
              child: SizedBox(
                height: 62,
                child: Row(
                  children: [
                    for (final key in _columnOrder)
                      SizedBox(
                        width: _columnWidths[key],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _certificateCell(key, certificate),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _certificateCell(String key, _Certificate certificate) {
    switch (key) {
      case 'owner':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(certificate.owner, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            Text(certificate.position, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Color(0xFF7B8998))),
          ],
        );
      case 'type':
        return Text(certificate.type, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10));
      case 'issuer':
        return Text(certificate.issuer, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10));
      case 'validTo':
        return Text(_date(certificate.to), style: const TextStyle(fontSize: 10));
      case 'remaining':
        return Text(_remaining(certificate.daysLeft),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _remainingColor(certificate)));
      case 'state':
        return _StateBadge(certificate.state);
      case 'registration':
        return _RegistrationBadge(certificate.registered);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _securityInfo() => const Card(child: Padding(
    padding: EdgeInsets.all(18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.security_outlined, size: 19, color: Color(0xFF477AA5)), SizedBox(width: 8), Text('Контроль безопасности', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800))]),
      SizedBox(height: 12),
      _InfoRow(title: 'Закрытые ключи', value: 'Не извлекаются и не хранятся приложением', icon: Icons.key_off_outlined),
      _InfoRow(title: 'Хранилище сертификатов', value: 'Не подключено. Данные на экране демонстрационные', icon: Icons.storage_outlined),
      _InfoRow(title: 'Криптопровайдер', value: 'CryptoPro CSP не подключён', icon: Icons.enhanced_encryption_outlined),
      _InfoRow(title: 'Проверка отзыва', value: 'CRL / OCSP не выполняется', icon: Icons.fact_check_outlined),
      SizedBox(height: 8),
      Text('Для промышленной эксплуатации потребуется интеграция с Windows Certificate Store и CryptoPro CSP, проверка цепочки доверия, срока действия и статуса отзыва сертификата, а также разграничение доступа к операциям.', style: TextStyle(fontSize: 11, height: 1.45, color: Color(0xFF68798B))),
    ]),
  ));

  void _showImportInfo() => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Добавление сертификата'),
    content: const Text('В рабочей версии здесь будет выбор сертификата из Windows Certificate Store или файла .cer с последующим разбором его полей и проверкой цепочки доверия.\n\nСейчас импорт отключён: приложение не читает хранилища Windows, не устанавливает сертификаты и не получает доступ к закрытым ключам.'),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть'))],
  ));

  void _showDetails(_Certificate c) => showDialog<void>(context: context, builder: (ctx) => Dialog(
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [const Expanded(child: Text('Карточка сертификата', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))), IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close))]),
          Text(c.id, style: const TextStyle(fontSize: 11, color: Color(0xFF8190A0))),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: Text(c.owner, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))), _StateBadge(c.state)]),
          const Divider(height: 26),
          _DetailRow('Тип сертификата', c.type),
          _DetailRow('Должность / назначение', c.position),
          const _DetailRow('Медицинская организация', 'ГБУЗ «Городская поликлиника № 12»'),
          _DetailRow('Удостоверяющий центр', c.issuer),
          _DetailRow('Серийный номер', c.serial),
          _DetailRow('Отпечаток сертификата (демо)', c.thumbprint),
          _DetailRow('Контейнер / хранилище', c.container),
          _DetailRow('Действителен с', _date(c.from)),
          _DetailRow('Действителен до', _date(c.to)),
          _DetailRow('Остаток срока', _remaining(c.daysLeft)),
          _DetailRow('Регистрация', c.registered ? 'Зарегистрирован (демо)' : 'Ожидает регистрации (демо)'),
          const Divider(height: 26),
          const Text('Доступные действия', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: () { Navigator.pop(ctx); _showActionInfo('Проверка сертификата', 'В рабочей версии будет выполнена криптографическая проверка сертификата, цепочки доверия и статуса отзыва через CRL / OCSP. Сейчас отображаются только демонстрационные атрибуты.'); }, icon: const Icon(Icons.verified_outlined, size: 17), label: const Text('Проверить')),
            OutlinedButton.icon(onPressed: () { Navigator.pop(ctx); _showActionInfo('Перевыпуск сертификата', 'Перевыпуск выполняется в удостоверяющем центре. Приложение сможет контролировать сроки, фиксировать новый сертификат и связывать его с владельцем после подключения соответствующего процесса.'); }, icon: const Icon(Icons.autorenew, size: 17), label: const Text('Перевыпустить')),
            OutlinedButton.icon(onPressed: () { Navigator.pop(ctx); _showActionInfo('Регистрация сертификата', 'Регистрация сертификата в информационных системах пока не выполняется. Для этого потребуется согласовать целевой API и правила привязки сертификата к сотруднику.'); }, icon: const Icon(Icons.app_registration, size: 17), label: const Text('Регистрация')),
          ]),
          const SizedBox(height: 12),
          const Text('Карточка содержит тестовые данные. Она не подтверждает наличие сертификата или доступность закрытого ключа.', style: TextStyle(fontSize: 10, color: Color(0xFF9A6700), height: 1.4)),
        ],
      )),
    ),
  ));

  void _showActionInfo(String title, String message) => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
    title: Text(title), content: Text(message),
    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно'))],
  ));
}

enum _CertificateState { active, expiring, expired, pending, revoked }

extension on _CertificateState {
  String get label => switch (this) {
    _CertificateState.active => 'Действует',
    _CertificateState.expiring => 'Истекает скоро',
    _CertificateState.expired => 'Истёк',
    _CertificateState.pending => 'Не зарегистрирован',
    _CertificateState.revoked => 'Отозван',
  };
  Color get color => switch (this) {
    _CertificateState.active => const Color(0xFF18794E),
    _CertificateState.expiring => const Color(0xFF9A6700),
    _CertificateState.expired || _CertificateState.revoked => const Color(0xFFB42318),
    _CertificateState.pending => const Color(0xFF175CD3),
  };
  Color get background => switch (this) {
    _CertificateState.active => const Color(0xFFE8F7EF),
    _CertificateState.expiring => const Color(0xFFFFF4D6),
    _CertificateState.expired || _CertificateState.revoked => const Color(0xFFFEECEB),
    _CertificateState.pending => const Color(0xFFEAF2FF),
  };
}

class _Certificate {
  _Certificate(this.id, this.owner, this.position, this.type, this.issuer, this.serial, this.thumbprint, this.container, this.from, this.to, this.registered, {this.revoked = false});
  final String id, owner, position, type, issuer, serial, thumbprint, container;
  final DateTime from, to;
  final bool registered;
  final bool revoked;
  int get daysLeft => to.difference(DateTime.now()).inDays;
  _CertificateState get state {
    if (revoked) return _CertificateState.revoked;
    if (daysLeft < 0) return _CertificateState.expired;
    if (daysLeft <= 30) return _CertificateState.expiring;
    if (!registered) return _CertificateState.pending;
    return _CertificateState.active;
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.width, this.title, this.value, this.note, this.color, this.icon);
  final double width;
  final String title, value, note;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: width < 150 ? double.infinity : width,
    child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 21)),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF748396))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        Text(note, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF8996A4))),
      ])),
    ]))),
  );
}

class _ExpiryAlert extends StatelessWidget {
  const _ExpiryAlert({required this.expired, required this.expiring});
  final int expired, expiring;
  @override
  Widget build(BuildContext context) {
    final danger = expired > 0;
    final color = danger ? const Color(0xFFB42318) : const Color(0xFF9A6700);
    final bg = danger ? const Color(0xFFFEECEB) : const Color(0xFFFFF4D6);
    return Container(width: double.infinity, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: .22))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(danger ? Icons.error_outline : Icons.warning_amber_rounded, color: color, size: 21),
        const SizedBox(width: 10),
        Expanded(child: Text([
          if (expired > 0) 'Истекли: $expired.',
          if (expiring > 0) 'Истекают в ближайшие 30 дней: $expiring.',
          'Проверьте возможность подписания документов и запланируйте перевыпуск.',
        ].join(' '), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge(this.state);
  final _CertificateState state;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: state.background, borderRadius: BorderRadius.circular(20)),
    child: Text(state.label, style: TextStyle(color: state.color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _RegistrationBadge extends StatelessWidget {
  const _RegistrationBadge(this.registered);
  final bool registered;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: registered ? const Color(0xFFE8F7EF) : const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(20)),
    child: Text(registered ? 'Зарегистрирован' : 'Ожидает', style: TextStyle(color: registered ? const Color(0xFF18794E) : const Color(0xFF175CD3), fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.title, this.value);
  final String title, value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 190, child: Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF7B8998)))),
      Expanded(child: SelectableText(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value, required this.icon});
  final String title, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF8190A0)),
      const SizedBox(width: 9),
      SizedBox(width: 175, child: Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF7B8998)))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
    ]),
  );
}

String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
String _dateTime(DateTime d) => '${_date(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String _remaining(int days) {
  if (days < 0) return 'Истёк ${days.abs()} дн. назад';
  if (days == 0) return 'Истекает сегодня';
  if (days == 1) return '1 день';
  return '$days дн.';
}
Color _remainingColor(_Certificate c) {
  if (c.state == _CertificateState.expired || c.state == _CertificateState.revoked) return const Color(0xFFB42318);
  if (c.state == _CertificateState.expiring) return const Color(0xFF9A6700);
  return const Color(0xFF18794E);
}
