import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ui/components/reusable_card.dart';
import '../ui/components/calendar_day_cell.dart';
import '../ui/theme.dart';
import '../services/planner_service.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PlannerService plannerService = PlannerService();

    return StreamBuilder<FarmingPlan?>(
      stream: plannerService.getActivePlan(),
      builder: (context, snapshot) {
        final hasPlan = snapshot.hasData && snapshot.data != null;
        final plan = snapshot.data;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: hasPlan ? FloatingActionButton(
            onPressed: () => _showAddTaskDialog(context, plan!.id),
            backgroundColor: AppTheme.primaryGreen,
            child: const Icon(Icons.add, color: Colors.white),
          ) : null,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, hasPlan, plan?.crop),
                
                if (snapshot.connectionState == ConnectionState.waiting)
                   const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),

                if (snapshot.hasError)
                   Padding(padding: const EdgeInsets.all(20), child: Text("Error: ${snapshot.error}")),

                if (!hasPlan && snapshot.connectionState == ConnectionState.active)
                  _buildEmptyState(context),

                if (hasPlan)
                  _buildActivePlanView(context, plan!),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader(BuildContext context, bool hasPlan, String? cropName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Planner',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                  Text(hasPlan ? 'Active Season' : 'No Active Plan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(hasPlan ? (cropName ?? 'My Farm') : 'Start Your Season',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            hasPlan 
              ? 'Tracking activities for your ${cropName ?? 'farm'}.' 
              : 'Create a plan to get a recommended schedule.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Icon(Icons.note_add_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "No active farming plan",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text(
            "Select a crop to generate a customized schedule for planting, care, and harvesting.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _showCreatePlanDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Create Plan"),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlanView(BuildContext context, FarmingPlan plan) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    // Find events in this month
    final eventsThisMonth = plan.events.where((e) => 
      e.date.year == now.year && e.date.month == now.month
    ).toList();

    // Upcoming tasks - show everything pending or completed recently
    // Sort by: pending first, then by date, then completed
    final allSortedTasks = List<PlanEvent>.from(plan.events)
        ..sort((a, b) {
           if (a.completed != b.completed) return a.completed ? 1 : -1;
           return a.date.compareTo(b.date);
        });

    final displayTasks = allSortedTasks.where((e) => 
        !e.completed || e.date.isAfter(now.subtract(const Duration(days: 2)))
    ).take(10).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Calendar
          ReusableCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMMM yyyy').format(now),
                        style: Theme.of(context).textTheme.titleMedium),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Su', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Mo', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Tu', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('We', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Th', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Fr', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Sa', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8),
                  itemCount: daysInMonth,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final hasEvent = eventsThisMonth.any((e) => e.date.day == day);
                    Color? dotColor;
                    if (hasEvent) {
                      final event = eventsThisMonth.firstWhere((e) => e.date.day == day);
                      if (event.completed) dotColor = Colors.grey;
                      else if (event.type == 'planting') dotColor = AppTheme.primaryGreen;
                      else if (event.type == 'harvest') dotColor = Colors.orange;
                      else dotColor = AppTheme.lightGreen;
                    }
                    
                    return CalendarDayCell(day: '$day', dotColor: dotColor);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tasks List
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Tasks", style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 12),
          
          if (displayTasks.isEmpty)
             const Padding(
               padding: EdgeInsets.all(20),
               child: Text("No upcoming tasks this season.", style: TextStyle(color: Colors.grey)),
             )
          else 
            ReusableCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: displayTasks.map((task) {
                  return Column(
                    children: [
                      CheckboxListTile(
                          value: task.completed,
                          onChanged: (val) {
                            if (val != null) {
                              PlannerService().toggleTaskCompletion(plan.id, task.id, val);
                            }
                          },
                          activeColor: AppTheme.primaryGreen,
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.completed ? TextDecoration.lineThrough : null,
                              color: task.completed ? Colors.grey : null,
                            ),
                          ),
                          subtitle: Text(DateFormat('MMM d').format(task.date)), 
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getColorForType(task.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: Icon(_getIconForType(task.type), size: 20, color: _getColorForType(task.type)),
                          ),
                      ),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
  
  Color _getColorForType(String type) {
    switch (type) {
      case 'planting': return AppTheme.primaryGreen;
      case 'harvest': return Colors.orange;
      case 'fertilizer': return Colors.blue;
      case 'custom': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'planting': return Icons.grass;
      case 'harvest': return Icons.shopping_basket;
      case 'fertilizer': return Icons.science;
      case 'custom': return Icons.edit_note;
      default: return Icons.check_circle_outline;
    }
  }

  void _showCreatePlanDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const _CreatePlanSheet(),
    );
  }

  void _showAddTaskDialog(BuildContext context, String planId) {
    showDialog(context: context, builder: (context) => _AddTaskDialog(planId: planId));
  }
}

class _AddTaskDialog extends StatefulWidget {
  final String planId;
  const _AddTaskDialog({required this.planId});

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _type = 'care';
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("New Task"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Task Title"),
                validator: (v) => v!.isEmpty ? "Required" : null,
                onSaved: (v) => _title = v!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'care', child: Text("General Care")),
                  DropdownMenuItem(value: 'fertilizer', child: Text("Fertilizer")),
                  DropdownMenuItem(value: 'harvest', child: Text("Harvest")),
                  DropdownMenuItem(value: 'custom', child: Text("Custom")),
                ],
                onChanged: (v) => setState(() => _type = v!),
                decoration: const InputDecoration(labelText: "Type"),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context, 
                    initialDate: _date,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030)
                  );
                  if (d != null) setState(() => _date = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Date",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(DateFormat('MMM d, yyyy').format(_date)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Add"),
        )
      ],
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        final task = PlanEvent(
          title: _title,
          date: _date,
          type: _type,
        );
        await PlannerService().addTask(widget.planId, task);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        // ignore error
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

class _CreatePlanSheet extends StatefulWidget {
  const _CreatePlanSheet();

  @override
  State<_CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends State<_CreatePlanSheet> {
  final PlannerService _service = PlannerService();
  String? _selectedCrop;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final availableCrops = _service.getAvailableCrops();
    final events = _selectedCrop != null 
        ? _service.generatePreview(_selectedCrop!, _startDate) 
        : <PlanEvent>[];

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 20
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Create New Plan", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          
          // Crop Selector
          DropdownButtonFormField<String>(
            value: _selectedCrop,
            decoration: InputDecoration(
              labelText: "Select Crop",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: availableCrops.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => setState(() => _selectedCrop = val),
          ),
          const SizedBox(height: 16),
          
          // Date Selector
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context, 
                initialDate: _startDate, 
                firstDate: DateTime(2023), 
                lastDate: DateTime(2030)
              );
              if (d != null) setState(() => _startDate = d);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: "Start Date (Sowing/Planting)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('MMMM d, yyyy').format(_startDate)),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Preview
          if (_selectedCrop != null) ...[
            Text("Recommended Schedule", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final e = events[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Text("${index + 1}", style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(e.title),
                    subtitle: Text(DateFormat('MMM d').format(e.date)),
                    dense: true,
                  );
                },
              ),
            ),
          ] else 
            const Expanded(child: Center(child: Text("Select a crop to see the plan."))),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedCrop == null || _isLoading ? null : _savePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("Accept & Create Plan"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePlan() async {
    setState(() => _isLoading = true);
    try {
      await _service.createPlan(_selectedCrop!, _startDate);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
