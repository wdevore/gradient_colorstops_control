import 'dart:html';

import 'package:color_slider_control/color_slider_control.dart';
import 'package:gradient_colorstops_control/gradient_colorstops_control.dart';

DivElement _targetColorContainer;
DivElement _targetGradientContainer;

/*
  color_slider_control:
    git: git://github.com/wdevore/color_slider_control.git
    path: /Users/williamdevore/Documents/Development/GitReposes/color_slider_control
 * 
 */
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
  
  window.onMouseMove.listen((MouseEvent e) {
    _mouseMove(e);
  });

}

void _mouseMove(MouseEvent e) {
  //print("MOUSE screen: ${e.screen}, client: ${e.client}, offset: ${e.offset}");
}
