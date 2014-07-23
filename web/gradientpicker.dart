import 'dart:html';

import 'package:color_slider_control/color_slider_control.dart';
import 'package:gradient_colorstops_control/gradient_colorstops_control.dart';

DivElement _targetColorContainer;
DivElement _targetGradientContainer;

void main() {
  ColorSliderWidget colorWidget = new ColorSliderWidget();
  _targetColorContainer = querySelector("#color_pickerId");
  _targetColorContainer.nodes.add(colorWidget.container);

  // We want the gradient widget to only send the colorstop of the marker
  // not the marker's color stop on the bar.
  GradientColorStopWidget gradientWidget = new GradientColorStopWidget(colorWidget.externalColorChange);
  gradientWidget.colorWidget = colorWidget;
  
  _targetGradientContainer = querySelector("#gradient_pickerId");
  _targetGradientContainer.nodes.add(gradientWidget.container);
  
  colorWidget.colorChangeCallback = gradientWidget.externalColorChange;
  
  colorWidget.bind();
  gradientWidget.bind();
  
}


