// features/categories/widgets/category_card.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final bool isCover;
  final bool isSelectable;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CategoryCard({
    super.key,
    required this.category,
    this.isCover = true,
    this.isSelectable = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            isCover
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Row(
                          children: [
                            Text(
                              category.icon,
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    category.name,
                                    style: AppTextStyles.body,
                                  ),
                                  Text(
                                    '${category.count} photos',
                                    style: AppTextStyles.label,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          child: Image.asset(
                            category.thumbnail!,
                            fit: BoxFit.cover,
                            height: 16.w,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Row(
                      children: [
                        Text(category.icon, style: TextStyle(fontSize: 16.sp)),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.name, style: AppTextStyles.body),
                              Text(
                                '${category.count} photos',
                                style: AppTextStyles.label,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

            // مؤشر التحديد - نسخة بديلة أوضح
            if (isSelected)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
