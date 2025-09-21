// Import package Flutter Material để sử dụng Color và Colors
import 'package:flutter/material.dart';

// File chứa các màu sắc constants được sử dụng trong toàn bộ app
// Giúp maintain consistency và dễ dàng thay đổi theme

// Màu nền cho mobile - màu đen hoàn toàn (0,0,0,1)
const mobileBackgroundColor = Color.fromRGBO(0,0,0,1);

// Màu nền cho web - màu xám đậm (18,18,18,1)
const webBackgroundColor = Color.fromRGBO(18,18,18,1);

// Màu nền cho search bar trên mobile - màu xám đậm (38,38,38,1)
const mobileSearchColor = Color.fromRGBO(38,38,38,1);

// Màu nền cho search bar trên web - màu xám đậm hơn (42,42,42,1)
const webSearchColor = Color.fromRGBO(42,42,42,1);

// Màu chính của app - màu xanh đậm (#1E1E2C)
const primaryColor = Color(0xFF1E1E2C);

// Màu phụ của app - màu xám từ Colors built-in
const secondaryColor = Colors.grey;

// Màu nhấn (accent) - màu tím xanh (#6C63FF) để highlight các element quan trọng
const Color accentColor = Color(0xFF6C63FF);
