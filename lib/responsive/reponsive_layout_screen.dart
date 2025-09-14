import 'package:flutter/material.dart';
import 'package:blogapp/responsive/dimension.dart';
class ReponsiveLayout extends StatelessWidget {
  final Widget webScreenLayout;
  final Widget mobileScreenLayout;
  const ReponsiveLayout({super.key, required this.webScreenLayout, required this.mobileScreenLayout});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
         if(constraints.maxWidth > webScreenSize) {
           //web layout
           return webScreenLayout;
         } else {
           //mobile layout
            return mobileScreenLayout;
         }
        }
    );
  }
}
