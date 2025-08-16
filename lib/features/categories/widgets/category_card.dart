import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final bool isCover;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.isCover = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isCover
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
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
      ),
    );
  }
}
