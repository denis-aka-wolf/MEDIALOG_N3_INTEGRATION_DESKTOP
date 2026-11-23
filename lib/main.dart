import 'package:flutter/material.dart';

void main() => runApp(const MedialogN3App());

const _navItems = <_NavItem>[
  _NavItem('Обзор', Icons.space_dashboard_outlined),
  _NavItem('Предварительный контроль', Icons.fact_check_outlined),
  _NavItem('Очередь СЭМД', Icons.outbox_outlined),
  _NavItem('Архив документов', Icons.folder_open_outlined),
  _NavItem('Журнал действий', Icons.receipt_long_outlined),
  _NavItem('Настройки', Icons.settings_outlined),
];

class MedialogN3App extends StatelessWidget {
  const MedialogN3App({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF142B45);
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
      child: Row(
        children: [
          const Text('Интеграция с ЕГИСЗ', style: TextStyle(color: Color(0xFF617286), fontSize: 12)),
          const Spacer(),
          const Icon(Icons.cloud_done_outlined, size: 17, color: Color(0xFF269B77)),
          const SizedBox(width: 7),
          const Text('Локальный режим', style: TextStyle(fontSize: 11, color: Color(0xFF526477))),
          const SizedBox(width: 20),
          const _DemoBadge(),
          const SizedBox(width: 18),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE7EFF7),
            child: Icon(Icons.person_outline, size: 18, color: Color(0xFF315879)),
          ),
          const SizedBox(width: 9),
          const Text('Оператор', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
      4 => const AuditPage(),
      _ => const SettingsPage(),
    };
  }
}

class _PagePadding extends StatelessWidget {
  final Widget child;
  const _PagePadding({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: child,
        ),
      ),
    );
  }
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
  final docs = const [
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
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = docs.where((d) {
      final matchesFilter = filter == 'Все' || (filter == 'Готовы' && d.type == 0) || (filter == 'Ошибки' && d.type == 2);
      final matchesQuery = '${d.id} ${d.name} ${d.doctor}'.toLowerCase().contains(query.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();
    return _PagePadding(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _PageHeading(title: 'Очередь СЭМД', subtitle: 'Подготовка, проверка и полуавтоматическая отправка документов'),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: const [
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
        const SizedBox(height: 12),
        Card(child: Column(children: [
          const _TableHeader(labels: ['ID ДОКУМЕНТА', 'ТИП СЭМД', 'ВРАЧ', 'ДАТА', 'СТАТУС']),
          for (final d in filtered)
            InkWell(
              onTap: () => showDialog(context: context, builder: (_) => _DocumentDialog(doc: d)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(children: [
                  Expanded(flex: 2, child: Text(d.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                  Expanded(flex: 4, child: Text(d.name, style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 2, child: Text(d.doctor, style: const TextStyle(fontSize: 11, color: Color(0xFF68798A)))),
                  Expanded(flex: 2, child: Text(d.date, style: const TextStyle(fontSize: 10, color: Color(0xFF8794A3)))),
                  Expanded(flex: 2, child: _StatusBadge(label: d.status, type: d.type)),
                ]),
              ),
            ),
          if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Text('Документы не найдены')),
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

class _TableHeader extends StatelessWidget {
  final List<String> labels;
  const _TableHeader({required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(bottom: BorderSide(color: Color(0xFFE8EDF2)))),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(flex: [2, 4, 2, 2, 2][i], child: Text(labels[i], style: const TextStyle(fontSize: 9, color: Color(0xFF8391A0), fontWeight: FontWeight.w800, letterSpacing: .4))),
      ]),
    );
  }
}

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});
  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  String query = '';
  _Doc? selectedDocument;

  static const documents = [
    _Doc('MED-001258', 'Протокол консультации', 'Смирнова Н.В.', 'Алексеева Мария Викторовна', 'ЭМК-00018452', '23.11.2026 11:18', 'Зарегистрирован', 0),
    _Doc('MED-001255', 'Протокол осмотра', 'Иванов И.И.', 'Громов Дмитрий Олегович', 'ЭМК-00018449', '23.11.2026 10:58', 'Зарегистрирован', 0),
    _Doc('MED-001254', 'Протокол инструментального исследования', 'Кузнецова Е.В.', 'Демидова Наталья Игоревна', 'ЭМК-00018448', '23.11.2026 10:51', 'Ожидает регистрации', 1),
    _Doc('MED-001253', 'Направление', 'Смирнова Н.В.', 'Егоров Михаил Андреевич', 'ЭМК-00018447', '23.11.2026 10:47', 'Зарегистрирован', 0),
    _Doc('MED-001252', 'Справка', 'Орлова М.Д.', 'Жукова Ольга Николаевна', 'ЭМК-00018446', '23.11.2026 10:43', 'Ошибка обработки', 2),
    _Doc('MED-001250', 'Протокол лабораторного исследования', 'Петрова А.С.', 'Ильина Татьяна Сергеевна', 'ЭМК-00018444', '23.11.2026 10:34', 'Зарегистрирован', 0),
    _Doc('MED-001249', 'Выписной эпикриз', 'Кузнецова Е.В.', 'Крылов Артём Евгеньевич', 'ЭМК-00018443', '23.11.2026 10:29', 'Ожидает регистрации', 1),
    _Doc('MED-001245', 'Протокол осмотра', 'Иванов И.И.', 'Осипов Владимир Михайлович', 'ЭМК-00018439', '23.11.2026 10:02', 'Зарегистрирован', 0),
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
      '${d.id} ${d.name} ${d.doctor} ${d.patient} ${d.emk}'
        .toLowerCase().contains(query.toLowerCase())
    ).toList();
    return _PagePadding(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _PageHeading(title: 'Архив документов', subtitle: 'Список сформированных СЭМД и переход к карточке каждого документа'),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: const [
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
          const _TableHeader(labels: ['ID ДОКУМЕНТА', 'ТИП СЭМД', 'ПАЦИЕНТ', 'ДАТА', 'СТАТУС']),
          for (final d in filtered)
            InkWell(
              onTap: () => setState(() => selectedDocument = d),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Expanded(flex: 2, child: Text(d.id, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                  Expanded(flex: 4, child: Text(d.name, style: const TextStyle(fontSize: 11))),
                  Expanded(flex: 3, child: Text(d.patient, style: const TextStyle(fontSize: 10, color: Color(0xFF68798A)))),
                  Expanded(flex: 2, child: Text(d.date, style: const TextStyle(fontSize: 10, color: Color(0xFF8794A3)))),
                  Expanded(flex: 2, child: _StatusBadge(label: d.status, type: d.type)),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8794A3)),
                ]),
              ),
            ),
          if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Text('Документы не найдены')),
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

class AuditPage extends StatelessWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    const events = [
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
    ];
    return _PagePadding(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _PageHeading(title: 'Журнал действий', subtitle: 'Аудит операций пользователей и системных процессов'),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: const [
          _MiniCount(label: 'Событий сегодня', value: '284'),
          _MiniCount(label: 'Успешно', value: '261'),
          _MiniCount(label: 'Ошибки', value: '12'),
          _MiniCount(label: 'Предупреждения', value: '11'),
        ]),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(children: [
          const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Поиск по событию, пользователю или ID')),
          const SizedBox(height: 12),
          const Row(children: [
            Expanded(child: Text('ВРЕМЯ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF8794A3)))),
            Expanded(flex: 3, child: Text('СОБЫТИЕ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF8794A3)))),
            Expanded(flex: 2, child: Text('ОБЪЕКТ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF8794A3)))),
            Expanded(flex: 2, child: Text('ПОЛЬЗОВАТЕЛЬ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF8794A3)))),
            Expanded(flex: 2, child: Text('РЕЗУЛЬТАТ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF8794A3)))),
          ]),
          const Divider(height: 18),
          for (final e in events)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                Expanded(child: Text(e.$1, style: const TextStyle(fontSize: 10, color: Color(0xFF77889A)))),
                Expanded(flex: 3, child: Text(e.$2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text(e.$3, style: const TextStyle(fontSize: 10))),
                Expanded(flex: 2, child: Text(e.$6, style: const TextStyle(fontSize: 10, color: Color(0xFF77889A)))),
                Expanded(flex: 2, child: _StatusBadge(label: e.$4, type: e.$5)),
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