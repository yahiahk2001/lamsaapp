import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../models/product_model.dart';
import '../../utils/colors.dart';
import './product_card.dart';

class SearchWidget extends StatefulWidget {
  final Function(bool)? onSearchStateChanged;
  final VoidCallback? onSearchCleared;
  
  const SearchWidget({
    super.key,
    this.onSearchStateChanged,
    this.onSearchCleared,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  List<ProductModel> _searchResults = [];
  bool _isSearchLoading = false;
  String _searchQuery = '';
  Timer? _debounceTimer;
  List<String> _searchHistory = [];
  bool _showSearchHistory = false;
  String _currentSortOrder = 'none'; // none, price_asc, price_desc
  
  // تحسينات الأداء
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const int _searchHistoryLimit = 10;
  
  // cache للبحث
  final Map<String, List<ProductModel>> _searchCache = {};
  static const int _maxCacheSize = 20;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _searchCache.clear();
    super.dispose();
  }

  void _loadSearchHistory() {
    // تحميل سجل البحث من التخزين المحلي
    // يمكن استخدام SharedPreferences هنا
    _searchHistory = [];
  }

  void _saveSearchHistory(String query) {
    if (query.trim().isNotEmpty && !_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > _searchHistoryLimit) {
        _searchHistory = _searchHistory.take(_searchHistoryLimit).toList();
      }
      // حفظ سجل البحث في التخزين المحلي
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      _searchQuery = query;
      
      // إلغاء البحث السابق إذا كان هناك
      _debounceTimer?.cancel();
      
      if (query.isEmpty) {
        // تحديث واحد بدلاً من تحديثات متعددة
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchResults.clear();
            _showSearchHistory = false;
            _isSearchLoading = false;
          });
          widget.onSearchStateChanged?.call(false);
          widget.onSearchCleared?.call();
        }
      } else {
        // تأخير البحث لمدة 300 مللي ثانية لتجنب البحث المتكرر
        _debounceTimer = Timer(_debounceDelay, () {
          if (mounted) {
            _performSearch(query);
          }
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty || !mounted) return;

    // تحديث واحد لحالة البحث
    setState(() {
      _isSearchLoading = true;
      _isSearching = true;
      _showSearchHistory = false;
    });

    widget.onSearchStateChanged?.call(true);

    try {
      List<ProductModel> results;
      
      // التحقق من وجود النتائج في الـ cache
      if (_searchCache.containsKey(query.toLowerCase())) {
        results = _searchCache[query.toLowerCase()]!;
      } else {
        // البحث من الخادم
        results = await context.read<HomeProvider>().searchProducts(query);
        
        // حفظ في الـ cache
        _cacheSearchResults(query.toLowerCase(), results);
      }
      
      if (mounted) {
        // تطبيق الترتيب أولاً ثم تحديث واحد
        List<ProductModel> sortedResults = List.from(results);
        _applySortingToList(sortedResults);
        
        setState(() {
          _searchResults = sortedResults;
          _isSearchLoading = false;
        });
        
        // حفظ البحث في السجل دون setState
        _saveSearchHistory(query);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchLoading = false;
          _searchResults.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في البحث'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    _searchFocusNode.unfocus();
    
    if (mounted) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
        _searchQuery = '';
        _showSearchHistory = false;
        _isSearchLoading = false;
        _currentSortOrder = 'none';
      });
      widget.onSearchStateChanged?.call(false);
      widget.onSearchCleared?.call();
    }
  }

  void _displaySearchHistory() {
    setState(() {
      _showSearchHistory = true;
    });
  }

  void _selectFromHistory(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
    // مسح سجل البحث من التخزين المحلي
  }

  void _cacheSearchResults(String query, List<ProductModel> results) {
    // إزالة أقدم النتائج إذا تجاوز الحد الأقصى
    if (_searchCache.length >= _maxCacheSize) {
      final oldestKey = _searchCache.keys.first;
      _searchCache.remove(oldestKey);
    }
    
    _searchCache[query] = List.from(results);
  }

  void _applySortingToList(List<ProductModel> products) {
    if (_currentSortOrder == 'price_asc') {
      products.sort((a, b) => a.price.compareTo(b.price));
    } else if (_currentSortOrder == 'price_desc') {
      products.sort((a, b) => b.price.compareTo(a.price));
    }
  }

  void _applySorting() {
    _applySortingToList(_searchResults);
    if (mounted) {
      setState(() {});
    }
  }

  void _showSearchFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE9ECEF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ترتيب النتائج',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Sort Options
                  _buildSortOption('السعر: من الأرخص إلى الأغلى', Icons.arrow_upward, 'price_asc'),
                  _buildSortOption('السعر: من الأغلى إلى الأرخص', Icons.arrow_downward, 'price_desc'),
                  
                  SizedBox(height: 16),
                  
                  // Apply Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.buttonColor, AppColors.buttonLightColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.buttonColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applySorting();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'تطبيق الترتيب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
    );
  }

  Widget _buildSortOption(String title, IconData icon, String sortType) {
    bool isSelected = _currentSortOrder == sortType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSortOrder = sortType;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.primaryColor.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryColor : AppColors.textSecondary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? AppColors.primaryColor : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'ابحث عن الحلويات المفضلة...',
          hintStyle: TextStyle(
            color: Color.fromARGB(255, 103, 109, 114),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.primaryColor,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Color(0xFF6C757D),
                    size: 20,
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF495057),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            _performSearch(value);
          }
        },
        onTap: () {
          // إظهار اقتراحات البحث عند النقر على حقل البحث
          if (_searchController.text.isEmpty) {
            _displaySearchHistory();
          }
        },
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'البحث السابق',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: _clearSearchHistory,
                  child: Icon(
                    Icons.clear_all,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ..._searchHistory.map((query) => _buildHistoryItem(query)),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String query) {
    return GestureDetector(
      onTap: () => _selectFromHistory(query),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.history,
              size: 16,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                query,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearchLoading) {
      return _buildSearchLoadingState();
    }

    if (_searchResults.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoSearchResults();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Results Header with Filter Options
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.primaryLightColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'نتائج البحث',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Spacer(),
              Text(
                '${_searchResults.length} منتج',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: 12),
              GestureDetector(
                onTap: _showSearchFilters,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentSortOrder != 'none' ? AppColors.primaryColor.withOpacity(0.1) : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _currentSortOrder != 'none' ? AppColors.primaryColor : AppColors.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sort,
                        size: 14,
                        color: _currentSortOrder != 'none' ? AppColors.primaryColor : AppColors.primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _currentSortOrder == 'none' ? 'ترتيب' : 
                        _currentSortOrder == 'price_asc' ? 'أرخص' : 'أغلى',
                        style: TextStyle(
                          fontSize: 10,
                          color: _currentSortOrder != 'none' ? AppColors.primaryColor : AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        
        // Search Results List with Performance Optimization
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final product = _searchResults[index];
            return ProductCard(product: product);
          },
        ),
      ],
    );
  }

  Widget _buildSearchLoadingState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonColor),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'جاري البحث...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.search_off,
                size: 40,
                color: Color(0xFF6C757D),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'جرب البحث بكلمات مختلفة',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Getters للوصول إلى الحالة الحالية للبحث
  bool get isSearching => _isSearching;
  bool get showSearchHistory => _showSearchHistory && _searchHistory.isNotEmpty;
  bool get hasSearchQuery => _searchQuery.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // إغلاق سجل البحث عند النقر خارجه
        if (_showSearchHistory) {
          setState(() {
            _showSearchHistory = false;
          });
          _searchFocusNode.unfocus();
        }
      },
      child: Column(
        children: [
          // Fixed Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildSearchField(),
          ),
          
          // Search Results or Search History
          if (_isSearching)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildSearchResults(),
              ),
            )
          else if (_showSearchHistory && _searchHistory.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildSearchHistory(),
              ),
            ),
        ],
      ),
    );
  }
}
