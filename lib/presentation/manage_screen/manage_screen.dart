import 'package:flutter/material.dart';
import 'package:kaarunyanursery/presentation/manage_screen/widgets/manage_plant_screen.dart';

import '../../theme/app_theme.dart';
import './widgets/manage_customers_tab_widget.dart';
import './widgets/manage_plants_tab_widget.dart';
import './widgets/manage_villages_tab_widget.dart';

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GlobalKey<ManagePlantsTabWidgetState> _plantsKey =
  GlobalKey<ManagePlantsTabWidgetState>();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleAddButton() {
    switch (_tabController.index) {
      case 0:
      // Plants
        _plantsKey.currentState?.showAddPlantDialog();
        break;

      case 1:
      // Customers
      // We will connect this later.
        break;

      case 2:
      // Villages
      // We will connect this later.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,

      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        automaticallyImplyLeading: false,

        title: Text(
          'Manage',
          style: theme.textTheme.titleLarge?.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],

        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: const Color(0xFF9E9E9E),
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,

          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),

          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),

          tabs: const [
            Tab(
              icon: Icon(
                Icons.eco_rounded,
                size: 18,
              ),
              text: 'Plants',
            ),

            Tab(
              icon: Icon(
                Icons.people_rounded,
                size: 18,
              ),
              text: 'Customers',
            ),

            Tab(
              icon: Icon(
                Icons.location_on_rounded,
                size: 18,
              ),
              text: 'Villages',
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: TabBarView(
          controller: _tabController,

          children: [
            ManagePlantsTabWidget(
              key: _plantsKey,
              onPlantTap: (plant) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManagePlantScreen(
                      plant: plant,
                    ),
                  ),
                );
              },
            ),

            const ManageCustomersTabWidget(),

            const ManageVillagesTabWidget(),
          ],
        ),
      ),

      floatingActionButton: AnimatedBuilder(
        animation: _tabController,

        builder: (context, child) {
          final labels = [
            'Add Plant',
            'Add Customer',
            'Add Village',
          ];

          final icons = [
            Icons.local_florist_rounded,
            Icons.person_add_rounded,
            Icons.add_location_rounded,
          ];

          return FloatingActionButton.extended(
            onPressed: _handleAddButton,

            icon: Icon(
              icons[_tabController.index],
            ),

            label: Text(
              labels[_tabController.index],
            ),

            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }
}