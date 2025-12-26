import 'package:flutter/material.dart';

class PlantFilterDrawer extends StatelessWidget {
  const PlantFilterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: const [
            _ExpandableFilterItem(
              title: 'گل و گیاهان رایج',
              icon: Icons.local_florist,
              children: [
                _SubFilterItem(title: 'گیاهان آپارتمانی'),
                _SubFilterItem(title: 'گیاهان زینتی'),
                _SubFilterItem(title: 'کاکتوس‌ها'),
              ],
            ),
            _ExpandableFilterItem(
              title: 'بر اساس محیط نگهداری',
              icon: Icons.home,
              children: [
                _SubFilterItem(title: 'فضای داخلی'),
                _SubFilterItem(title: 'فضای باز'),
                _SubFilterItem(title: 'بالکن'),
              ],
            ),
            _ExpandableFilterItem(
              title: 'بر اساس میزان آبیاری',
              icon: Icons.water_drop,
              children: [
                _SubFilterItem(title: 'کم'),
                _SubFilterItem(title: 'متوسط'),
                _SubFilterItem(title: 'زیاد'),
              ],
            ),
            _ExpandableFilterItem(
              title: 'بر اساس میزان نور',
              icon: Icons.wb_sunny,
              children: [
                _SubFilterItem(title: 'کم‌نور'),
                _SubFilterItem(title: 'نور متوسط'),
                _SubFilterItem(title: 'پرنور'),
              ],
            ),
            _DrawerItem(
              title: 'بر اساس میزان دما',
              icon: Icons.thermostat,
            ),
            _DrawerItem(
              title: 'دارای خواص درمانی',
              icon: Icons.favorite_border,
            ),
            Divider(),
            _DrawerItem(
              title: 'نمایش همه گل‌ها و گیاهان',
              icon: Icons.done_all,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- expandable item -------------------- */

class _ExpandableFilterItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ExpandableFilterItem({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 15),
      ),
      children: children,
    );
  }
}

/* -------------------- single item -------------------- */

class _DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isPrimary;

  const _DrawerItem({
    required this.title,
    required this.icon,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {},
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16),
      trailing: const Icon(Icons.chevron_right),
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 15,
          fontWeight:
          isPrimary ? FontWeight.bold : FontWeight.normal,
          color: isPrimary ? Colors.green : Colors.black87,
        ),
      ),
      leading: Icon(
        icon,
        color: isPrimary ? Colors.green : Colors.grey[700],
      ),
    );
  }
}

/* -------------------- sub item -------------------- */

class _SubFilterItem extends StatelessWidget {
  final String title;

  const _SubFilterItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {},
      contentPadding:
      const EdgeInsets.only(right: 32, left: 16),
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: const Icon(
        Icons.chevron_left,
        size: 18,
        color: Colors.grey,
      ),
    );
  }
}
