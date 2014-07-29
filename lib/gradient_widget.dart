part of gradient_colorstops_control;

/**
 * This widget is a single control with markers:
 *  0                                            1
 *  ------------------ gradient ------------------
 *  |  |      | |                   |    |       |
 *  ^  ^      ^ ^                   ^    ^       ^  color stops
 *  
 * There is always two stops at the Begin and End of the gradient.
 * Crtl-Dragging a Begin or End, or double clicking will cause a new Stop
 * to be generated.
 * 
 * Loading:
 * If we are loading then no events are sent to the color control (CC).
 * We only send events to CC when the user interacts.
 * 
 * Sorting is automatic in that the marker positions represent the order.
 * For each event we build the css gradient based on their position on the bar.
 * The position(0 -> width) is converted into a location(0.0 -> 1.0)
 * 
 * To build the css we:
 * 1) copy the marker positions
 * 2) sort positions
 * 3) rebuild css from position by referencing the matching ColorData.
 */
class GradientColorStopWidget {
  DivElement container;
  DivElement innerContainer;

  ColorSlider _colorSlider;
  
  bool _down = false;
  BaseSlider target;
  
  bool _draggingEndStop = false;
  
  ColorChangedEvent _changeCallback;
  ColorSliderWidget colorWidget;
  
  GradientColorStopWidget([ColorChangedEvent changeCallback = null]) {
    _changeCallback = changeCallback;
    
    container = new DivElement();
    container.classes.add("stops_color_container");

    innerContainer = new DivElement();
    innerContainer.classes.add("stops_gradient_container");
    container.nodes.add(innerContainer);
    
    _colorSlider = new ColorSlider();
    _colorSlider.init("stops_color_rainbow");
    _colorSlider.barTitle = "DoubleClick to create color Stop. Alt-DoubleClick on Stop to delete.";
    target = _colorSlider;
    
    List<ColorValue> colors = [
       new ColorValue.fromRGB(0, 0, 255), 
       new ColorValue.fromRGB(255, 127, 0)
       ];
    _colorSlider.buildGradient(colors);
    
    innerContainer.nodes.add(_colorSlider.container);
    
    container.onMouseDown.listen((MouseEvent e) {
      _mouseDown(e);
    });
    container.onMouseMove.listen((MouseEvent e) {
      _mouseMove(e);
    });
    container.onMouseUp.listen((MouseEvent e) {
      _mouseUp(e);
    });
    container.onDoubleClick.listen((MouseEvent e) {
      _mouseDoubleClick(e);
    });
  }

  /**
   * 0.0 for Left side (aka beginning Stop)
   * 1.0 for right side (aka ending Stop)
   */
  void bind([List<ColorData> stops = null]) {
    _colorSlider.bind(null);
    
    if (stops == null) {
      // Load the default End Stops.
      ColorData cs = _addMarkerWithLoc(0.0);
      cs.isEndStop = true;
      _colorSlider.highlightAsEndMarker(cs);
      
      cs = _addMarkerWithLoc(1.0);
      cs.isEndStop = true;
      _colorSlider.highlightAsEndMarker(cs);
      
      _colorSlider.updateCSSGradientWithStops();
    }
    else {
      _colorSlider.markers.clear();
      
      for(ColorData cs in stops) {
        _colorSlider.markers.add(cs);
        _addMarkerWithLoc(cs.gradientlocation, cs);
        _colorSlider.highlightAsUnSelected(cs); 
      }
      
      _colorSlider.highlightAsEndMarker(stops[0]);
      _colorSlider.highlightAsEndMarker(stops[stops.length - 1]);
      _colorSlider.updateCSSGradientWithStops();
    }
    
  }
  
  void _mouseDown(MouseEvent e) {
    // Find and Activate icon.
    ColorData selectedStop = _colorSlider.selectedMarker(e.target);

    if (selectedStop == null)
      return;
    
    _unselectAll();
    
    _colorSlider.highlightAsSelected(selectedStop);
    
    if (selectedStop != null) {
      _down = true;
      _draggingEndStop = selectedStop.isEndStop;
      
      target.mouseDown(getXOffset(e));
      
      // Also send an external event for "down".
      _markerClicked(selectedStop);

      e.preventDefault();
    }
  }

  ColorData _addMarkerWithLoc(double gradientLoc, [ColorData stop = null]) {
    ColorData cs = stop;
    if (cs == null) {
      // We weren't given ColorData so ask the color picker for one.
      cs = new ColorData.copy(colorWidget.currentColorData);
    }

    cs.gradientlocation = gradientLoc;
    // We always need an icon.
    ImageElement ime = _colorSlider.addMarkerToBottom(cs, Base64Resources.markerPin);

    _colorSlider.location = cs.gradientlocation;
    return cs;
  }
  
  ColorData _addMarker(int x, [int offset = 0]) {
    // Get location relative to gradient bar.
    double loc = _colorSlider.getLocation(x - offset);
    return _addMarkerWithLoc(loc);
  }
  
  void _deleteMarker(HtmlElement target) {
    _colorSlider.removeMarker(target);
  }
  
  void _mouseMove(MouseEvent e) {
    if (_down && target != null) {
      if (e.altKey) {
        print("create new stop based on clicked on stop.");
      }
      else if (!_draggingEndStop) {
        // Update icon position
        target.mouseMove(getXOffset(e));
        
        // Update selected color stop as well.
        Point np = window.convertPointFromPageToNode(_colorSlider.gradientElement, e.client);
        double loc = _colorSlider.getLocation(np.x.toInt() + _colorSlider.iconWidth);
        _colorSlider.selectedStop.gradientlocation = loc;
        
        _colorSlider.updateCSSGradientWithStops();
      }
      
    }
    
    e.preventDefault();
  }

  void _unselectAll() {
    _colorSlider.unselectAll();
  }
  
  int getXOffset(MouseEvent e) {
    return e.client.x;//e.offset.x + _colorSlider.iconCenter * 2;
  }
  
  void _mouseDoubleClick(MouseEvent e) {
    if (!e.altKey) {
      // Add marker at cursor position
      // Did they doubleclick on an existing marker or the gradient bar?
      // the bar not an icon.
      ColorData selectedStop;
//      print("-----------------");
//      print("client: ${e.client}");
//      print("offset: ${e.offset}");
      
      if (e.target == _colorSlider.gradientElement) {
        _unselectAll();
        selectedStop = _addMarker(e.offset.x, -_colorSlider.iconWidth);
        _colorSlider.highlightAsSelected(selectedStop);
      }
      else {
        // Map marker position in bar position.
//        int position = e.client.x - _colorSlider.leftOffset + _colorSlider.iconCenter;
//        print("pos: $position");
//        // client: 288 - 167 = 121
//        // 520 - 492 = 28   --> 167
//        selectedStop = _addMarker(e.client.x, -_colorSlider.iconWidth);
      }
      
    }
    else {
      // They alt-doubleclicked on a marker. So delete it.
      
      // Find matching color stop.
      ColorData cd = _colorSlider.selectedMarker(e.target);
      
      if (cd != null)
        if (!cd.isEndStop)
          _deleteMarker(e.target);
      
      _unselectAll();
    }

    _colorSlider.updateCSSGradientWithStops();
  }
  
  void _mouseUp(MouseEvent e) {
    _down = false;
    _draggingEndStop = false;
  }

  void _markerClicked(ColorData stop) {
    if (_changeCallback != null) {
      _changeCallback(stop);
    }    
  }
  
  void externalColorChange(ColorData stop) {
    _colorSlider.replaceSelectedWith(stop);
  }
}