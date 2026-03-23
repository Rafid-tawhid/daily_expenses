import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedWeek = DateTime.now();
  String _selectedChartType = 'pie';
  String _selectedTimeFrame = 'monthly'; // 'weekly', 'monthly'
  int _selectedWeekIndex = 0;

  // Get weeks in month
  List<DateTime> _getWeeksInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    List<DateTime> weeks = [];
    DateTime weekStart = firstDay;

    while (weekStart.isBefore(lastDay)) {
      weeks.add(weekStart);
      weekStart = weekStart.add(const Duration(days: 7));
    }

    return weeks;
  }

  // Get week range string
  String _getWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final month = weekStart.month;

    return '${_getMonthName(month)} ${weekStart.day} - ${weekEnd.day}';
  }

  // Filter transactions for selected week
  List<Transaction> _getWeeklyTransactions(List<Transaction> transactions, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));

    return transactions.where((t) {
      return t.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          t.date.isBefore(weekEnd.add(const Duration(days: 1)));
    }).toList();
  }

  // Calculate weekly stats
  Map<String, dynamic> _calculateWeeklyStats(List<Transaction> weeklyTransactions) {
    double income = 0;
    double expense = 0;
    Map<String, double> categoryExpenses = {};

    for (var t in weeklyTransactions) {
      if (t.type == 'income') {
        income += t.amount;
      } else {
        expense += t.amount;
        if (t.category != null) {
          categoryExpenses[t.category!.name] =
              (categoryExpenses[t.category!.name] ?? 0) + t.amount;
        }
      }
    }

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
      'count': weeklyTransactions.length,
      'categoryExpenses': categoryExpenses,
    };
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final categories = ref.watch(categoryProvider);
    final summary = ref.watch(summaryProvider);

    // Filter transactions for selected month
    final monthlyTransactions = transactions.where((t) {
      return t.date.month == _selectedMonth.month &&
          t.date.year == _selectedMonth.year;
    }).toList();

    // Calculate monthly stats
    double monthlyIncome = 0;
    double monthlyExpense = 0;
    for (var t in monthlyTransactions) {
      if (t.type == 'income') {
        monthlyIncome += t.amount;
      } else {
        monthlyExpense += t.amount;
      }
    }

    // Group expenses by category for pie chart (monthly)
    Map<String, double> monthlyCategoryExpenses = {};
    for (var t in monthlyTransactions.where((t) => t.type == 'expense')) {
      if (t.category != null) {
        monthlyCategoryExpenses[t.category!.name] =
            (monthlyCategoryExpenses[t.category!.name] ?? 0) + t.amount;
      }
    }

    // Weekly data
    final weeks = _getWeeksInMonth(_selectedMonth);
    final selectedWeek = weeks[_selectedWeekIndex];
    final weeklyTransactions = _getWeeklyTransactions(monthlyTransactions, selectedWeek);
    final weeklyStats = _calculateWeeklyStats(weeklyTransactions);

    // Prepare data for bar chart (daily expenses)
    Map<int, double> dailyExpenses = {};
    for (var t in (_selectedTimeFrame == 'monthly'
        ? monthlyTransactions
        : weeklyTransactions).where((t) => t.type == 'expense')) {
      dailyExpenses[t.date.day] = (dailyExpenses[t.date.day] ?? 0) + t.amount;
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        actions: [
          // Time frame selector
          Container(

            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'weekly',
                  label: Text('Weekly', style: TextStyle(fontWeight: FontWeight.w600)),
                  icon: Icon(Icons.check, size: 18),
                ),
                ButtonSegment(
                  value: 'monthly',
                  label: Text('Monthly', style: TextStyle(fontWeight: FontWeight.w600)),
                  icon: Icon(Icons.calendar_month, size: 18),
                ),
              ],
              selected: {_selectedTimeFrame},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedTimeFrame = selection.first;
                });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return Colors.transparent;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF4157FF);
                  }
                  return Colors.white;
                }),
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.white.withOpacity(0.1);
                  }
                  return Colors.transparent;
                }),
                side: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return BorderSide.none;
                  }
                  return BorderSide(color: Colors.white.withOpacity(0.3));
                }),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
          // Month picker
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                setState(() {
                  _selectedMonth = DateTime(picked.year, picked.month);
                  _selectedWeekIndex = 0;
                });
              }
            },
          ),
          // Chart type selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.bar_chart),
            onSelected: (value) {
              setState(() {
                _selectedChartType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pie',
                child: Row(
                  children: [
                    Icon(Icons.pie_chart),
                    SizedBox(width: 8),
                    Text('Pie Chart'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'bar',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart),
                    SizedBox(width: 8),
                    Text('Bar Chart'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'line',
                child: Row(
                  children: [
                    Icon(Icons.show_chart),
                    SizedBox(width: 8),
                    Text('Line Chart'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(transactionsProvider.future);
          await ref.refresh(categoriesProvider.future);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time period selector header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4157FF),
                      const Color(0xFF4157FF).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTimeFrame == 'weekly' ? 'Weekly Report' : 'Monthly Report',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedTimeFrame == 'weekly'
                                  ? _getWeekRange(selectedWeek)
                                  : '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedTimeFrame == 'weekly' && weeks.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, size: 20),
                                  onPressed: _selectedWeekIndex > 0
                                      ? () {
                                    setState(() {
                                      _selectedWeekIndex--;
                                    });
                                  }
                                      : null,
                                  color: Colors.white,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                Text(
                                  'Week ${_selectedWeekIndex + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, size: 20),
                                  onPressed: _selectedWeekIndex < weeks.length - 1
                                      ? () {
                                    setState(() {
                                      _selectedWeekIndex++;
                                    });
                                  }
                                      : null,
                                  color: Colors.white,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Summary cards for selected period
                    Row(
                      children: [
                        Expanded(
                          child: _buildCompactSummaryCard(
                            title: 'Income',
                            amount: _selectedTimeFrame == 'monthly' ? monthlyIncome : weeklyStats['income'],
                            icon: Icons.trending_up,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCompactSummaryCard(
                            title: 'Expense',
                            amount: _selectedTimeFrame == 'monthly' ? monthlyExpense : weeklyStats['expense'],
                            icon: Icons.trending_down,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCompactSummaryCard(
                            title: 'Balance',
                            amount: _selectedTimeFrame == 'monthly'
                                ? monthlyIncome - monthlyExpense
                                : weeklyStats['balance'],
                            icon: Icons.account_balance_wallet,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Spending Overview Section
              _buildSectionHeader(
                context,
                title: 'Spending Overview',
                subtitle: 'Visual breakdown of your expenses',
              ),

              const SizedBox(height: 16),

              // Chart container
              if ((_selectedTimeFrame == 'monthly' && monthlyExpense == 0) ||
                  (_selectedTimeFrame == 'weekly' && weeklyStats['expense'] == 0))
                _buildEmptyState()
              else
                Container(
                  height: 320,
                  padding: const EdgeInsets.all(16),
                  decoration: _buildCardDecoration(),
                  child: _selectedChartType == 'pie'
                      ? _buildPieChart(_selectedTimeFrame == 'monthly'
                      ? monthlyCategoryExpenses
                      : weeklyStats['categoryExpenses'])
                      : _selectedChartType == 'bar'
                      ? _buildBarChart(dailyExpenses, _selectedTimeFrame == 'monthly'
                      ? _getDaysInMonth(_selectedMonth)
                      : 7)
                      : _buildLineChart(dailyExpenses, _selectedTimeFrame == 'monthly'
                      ? _getDaysInMonth(_selectedMonth)
                      : 7),
                ),

              const SizedBox(height: 32),

              // Category Breakdown Section
              _buildSectionHeader(
                context,
                title: 'Category Breakdown',
                subtitle: 'Where your money is going',
              ),

              const SizedBox(height: 16),

              // Category breakdown cards
              _buildCategoryBreakdown(
                _selectedTimeFrame == 'monthly'
                    ? monthlyCategoryExpenses
                    : weeklyStats['categoryExpenses'],
                categories,
                _selectedTimeFrame == 'monthly' ? monthlyExpense : weeklyStats['expense'],
              ),

              const SizedBox(height: 32),

              // Budget vs Actual Section (only show if there are budgets)
              if (categories.any((c) => c.budgetLimit != null)) ...[
                _buildSectionHeader(
                  context,
                  title: 'Budget vs Actual',
                  subtitle: 'Track your spending against budget',
                ),
                const SizedBox(height: 16),
                ...categories.where((c) => c.budgetLimit != null).map((category) {
                  final spent = monthlyCategoryExpenses[category.name] ?? 0;
                  final budget = category.budgetLimit!;
                  final percentage = (spent / budget * 100).clamp(0, 100);
                  final isOverBudget = spent > budget;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: _buildCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                        category.color.replaceFirst('#', '0xFF'),
                                      ),
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(category.icon),
                                    size: 18,
                                    color: Color(
                                      int.parse(
                                        category.color.replaceFirst('#', '0xFF'),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${spent.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isOverBudget ? Colors.red : Colors.green,
                                  ),
                                ),
                                Text(
                                  'of \$${budget.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Stack(
                          children: [
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            Container(
                              height: 10,
                              width: MediaQuery.of(context).size.width * 0.7 * (percentage / 100),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isOverBudget
                                      ? [Colors.red, Colors.orange]
                                      : [Colors.green, Colors.lightGreen],
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}% used',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverBudget ? Colors.red : Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 8),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> categoryExpenses, List<Category> categories, double totalExpense) {
    if (categoryExpenses.isEmpty) {
      return _buildEmptyState(message: 'No expenses in this period');
    }

    final sortedEntries = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: _buildCardDecoration(),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedEntries.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          final category = categories.firstWhere(
                (c) => c.name == entry.key,
            orElse: () => categories.first,
          );
          final percentage = (entry.value / totalExpense * 100);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(
                        category.color.replaceFirst('#', '0xFF'),
                      ),
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(category.icon),
                    color: Color(
                      int.parse(
                        category.color.replaceFirst('#', '0xFF'),
                      ),
                    ),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          Color(
                            int.parse(
                              category.color.replaceFirst('#', '0xFF'),
                            ),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({String message = 'No expenses to display'}) {
    return Container(
      height: 300,
      decoration: _buildCardDecoration(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, double> categoryExpenses) {
    if (categoryExpenses.isEmpty) {
      return const Center(
        child: Text('No data to display'),
      );
    }

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    int colorIndex = 0;
    final pieSections = categoryExpenses.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.value.toStringAsFixed(0)}',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        showTitle: true,
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: pieSections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
          enabled: true,
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<int, double> dailyExpenses, int days) {
    if (dailyExpenses.isEmpty) {
      return const Center(
        child: Text('No data to display'),
      );
    }

    final maxAmount = dailyExpenses.values.fold(0.0, (max, e) => e > max ? e : max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxAmount * 1.1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '\$${rod.toY.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 1 && value.toInt() <= days) {
                  return Text(value.toInt().toString());
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(days, (index) {
          final day = index + 1;
          final amount = dailyExpenses[day] ?? 0;
          return BarChartGroupData(
            x: day,
            barRods: [
              BarChartRodData(
                toY: amount,
                color: const Color(0xFF4157FF),
                width: days > 20 ? 8 : 12,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(Map<int, double> dailyExpenses, int days) {
    if (dailyExpenses.isEmpty) {
      return const Center(
        child: Text('No data to display'),
      );
    }

    final maxAmount = dailyExpenses.values.fold(0.0, (max, e) => e > max ? e : max);

    final spots = List.generate(days, (index) {
      final day = index + 1;
      return FlSpot(day.toDouble(), dailyExpenses[day] ?? 0);
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxAmount / 5,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 1 && value.toInt() <= days) {
                  return Text(value.toInt().toString());
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('\$${value.toInt()}');
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 1,
        maxX: days.toDouble(),
        minY: 0,
        maxY: maxAmount * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF4157FF),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF4157FF).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'food':
      case 'restaurant':
        return Icons.restaurant;
      case 'transport':
      case 'transportation':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
      case 'utilities':
        return Icons.receipt;
      case 'health':
      case 'medical':
        return Icons.health_and_safety;
      case 'education':
        return Icons.school;
      case 'salary':
        return Icons.work;
      default:
        return Icons.category;
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
}