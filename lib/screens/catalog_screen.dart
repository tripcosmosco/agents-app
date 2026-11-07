import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/catalog_item_model.dart';
import '../providers/catalog_provider.dart';
import '../widgets/glass_card.dart';
import 'quotation_desk_screen.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  static void open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CatalogScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final isLight = Theme.of(context).brightness == Brightness.light;
    final items = catalog.items;
    final categories = catalog.categories;

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF070D1E),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AppBar(
              backgroundColor: (isLight ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.88),
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: 14,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isLight ? AppColors.lightTextPrimary : Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tour & Package Catalog',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: isLight ? AppColors.lightTextPrimary : Colors.white,
                          ),
                        ),
                        Text(
                          'Standard Tariffs, Charters & Fixed Pilgrimage Packages',
                          style: TextStyle(fontSize: 10, color: isLight ? AppColors.lightTextMuted : Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Sync Offerings',
                  icon: catalog.isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGold))
                      : const Icon(Icons.sync_rounded, size: 20, color: AppColors.accentGold),
                  onPressed: catalog.isLoading ? null : () => catalog.syncWithBackend(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Row
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            color: (isLight ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.6),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => catalog.setSearchQuery(val),
                  style: TextStyle(fontSize: 13, color: isLight ? AppColors.lightTextPrimary : Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search packages, cabs, charters, hotels...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    filled: true,
                    fillColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = catalog.selectedCategory.toLowerCase() == cat.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => catalog.setCategory(cat),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF59E0B).withValues(alpha: isLight ? 0.15 : 0.28)
                                  : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFF59E0B).withValues(alpha: 0.6) : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              cat.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? const Color(0xFFF59E0B) : (isLight ? AppColors.lightTextMuted : Colors.white60),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('No offerings found matching your criteria.',
                        style: TextStyle(color: isLight ? AppColors.lightTextMuted : Colors.white60)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildCatalogCard(context, item, isLight);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogCard(BuildContext context, CatalogItem item, bool isLight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.badge.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.badge.toUpperCase(),
                                style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 9, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            item.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isLight ? AppColors.lightTextMuted : Colors.white60,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isLight ? AppColors.lightTextPrimary : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item.formattedPrice,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 11.5,
                color: isLight ? AppColors.lightTextMuted : Colors.white70,
              ),
            ),
            if (item.features.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.features.map((f) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          f,
                          style: TextStyle(
                            fontSize: 10,
                            color: isLight ? Colors.black87 : Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.post_add_rounded, size: 14),
                  label: const Text('Add to Quotation', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuotationDeskScreen(initialCatalogItem: item),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
