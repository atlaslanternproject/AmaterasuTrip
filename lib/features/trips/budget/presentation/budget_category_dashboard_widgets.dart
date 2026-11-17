// Parte di budget_category_dashboard.dart: piccoli widget
// (schede e indicatori) della dashboard.

// ignore_for_file: invalid_use_of_protected_member
part of 'budget_category_dashboard.dart';

extension _BudgetCategoryDashboardStateWidgets on _BudgetCategoryDashboardState {
  Widget _tab(String label, IconData icon, bool personal) {
    final chosen = _chartPersonal == personal;
    return Expanded(
      child: Material(
        color: chosen ? _BudgetCategoryDashboardState._orange : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _chartPersonal = personal),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: chosen ? _BudgetCategoryDashboardState._dark : _BudgetCategoryDashboardState._muted),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: chosen ? FontWeight.w700 : FontWeight.w500,
                      color: chosen ? _BudgetCategoryDashboardState._dark : _BudgetCategoryDashboardState._cream,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _overviewMetric(String label, String value, {bool accent = false}) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AmaterasuColors.surfaceTooltip,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AmaterasuColors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _BudgetCategoryDashboardState._muted, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent ? _BudgetCategoryDashboardState._gold : _BudgetCategoryDashboardState._cream,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
