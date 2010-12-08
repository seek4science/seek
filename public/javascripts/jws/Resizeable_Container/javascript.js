function Position(x, y)
{
  this.X = x;
  this.Y = y;
  
  this.Add = function(val)
  {
    var newPos = new Position(this.X, this.Y);
    if(val != null)
    {
      if(!isNaN(val.X))
        newPos.X += val.X;
      if(!isNaN(val.Y))
        newPos.Y += val.Y
    }
    return newPos;
  }
  
  this.Subtract = function(val)
  {
    var newPos = new Position(this.X, this.Y);
    if(val != null)
    {
      if(!isNaN(val.X))
        newPos.X -= val.X;
      if(!isNaN(val.Y))
        newPos.Y -= val.Y
    }
    return newPos;
  }
  
  this.Min = function(val)
  {
    var newPos = new Position(this.X, this.Y)
    if(val == null)
      return newPos;
    
    if(!isNaN(val.X) && this.X > val.X)
      newPos.X = val.X;
    if(!isNaN(val.Y) && this.Y > val.Y)
      newPos.Y = val.Y;
    
    return newPos;  
  }
  
  this.Max = function(val)
  {
    var newPos = new Position(this.X, this.Y)
    if(val == null)
      return newPos;
    
    if(!isNaN(val.X) && this.X < val.X)
      newPos.X = val.X;
    if(!isNaN(val.Y) && this.Y < val.Y)
      newPos.Y = val.Y;
    
    return newPos;  
  }  
  
  this.Bound = function(lower, upper)
  {
    var newPos = this.Max(lower);
    return newPos.Min(upper);
  }
  
  this.Check = function()
  {
    var newPos = new Position(this.X, this.Y);
    if(isNaN(newPos.X))
      newPos.X = 0;
    if(isNaN(newPos.Y))
      newPos.Y = 0;
    return newPos;
  }
  
  this.Apply = function(element)
  {
    if(typeof(element) == "string")
      element = document.getElementById(element);
    if(element == null)
      return;
    if(!isNaN(this.X))
      element.style.left = this.X + 'px';
    if(!isNaN(this.Y))
      element.style.top = this.Y + 'px';  
  }
}

function hookEvent(element, eventName, callback)
{
  if(typeof(element) == "string")
    element = document.getElementById(element);
  if(element == null)
    return;
  if(element.addEventListener)
  {
    element.addEventListener(eventName, callback, false);
  }
  else if(element.attachEvent)
    element.attachEvent("on" + eventName, callback);
}

function unhookEvent(element, eventName, callback)
{
  if(typeof(element) == "string")
    element = document.getElementById(element);
  if(element == null)
    return;
  if(element.removeEventListener)
    element.removeEventListener(eventName, callback, false);
  else if(element.detachEvent)
    element.detachEvent("on" + eventName, callback);
}

function cancelEvent(e)
{
  e = e ? e : window.event;
  if(e.stopPropagation)
    e.stopPropagation();
  if(e.preventDefault)
    e.preventDefault();
  e.cancelBubble = true;
  e.cancel = true;
  e.returnValue = false;
  return false;
}

function getMousePos(eventObj)
{
  eventObj = eventObj ? eventObj : window.event;
  var pos;
  if(isNaN(eventObj.layerX))
    pos = new Position(eventObj.offsetX, eventObj.offsetY);
  else
    pos = new Position(eventObj.layerX, eventObj.layerY);
  return correctOffset(pos, pointerOffset, true);
}

function getEventTarget(e)
{
  e = e ? e : window.event;
  return e.target ? e.target : e.srcElement;
}

function absoluteCursorPostion(eventObj)
{
  eventObj = eventObj ? eventObj : window.event;
  
  if(isNaN(window.scrollX))
    return new Position(eventObj.clientX + document.documentElement.scrollLeft + document.body.scrollLeft, 
      eventObj.clientY + document.documentElement.scrollTop + document.body.scrollTop);
  else
    return new Position(eventObj.clientX + window.scrollX, eventObj.clientY + window.scrollY);
}

function dragObject(element, attachElement, lowerBound, upperBound, startCallback, moveCallback, endCallback, attachLater)
{
  if(typeof(element) == "string")
    element = document.getElementById(element);
  if(element == null)
      return;

  var cursorStartPos = null;
  var elementStartPos = null;
  var dragging = false;
  var listening = false;
  var disposed = false;

  function dragStart(eventObj)
  {
    if(dragging || !listening || disposed) return;
    dragging = true;

    if(startCallback != null)
      startCallback(eventObj, element);

    cursorStartPos = absoluteCursorPostion(eventObj);

    elementStartPos = new Position(parseInt(element.style.left), parseInt(element.style.top));

    elementStartPos = elementStartPos.Check();

    hookEvent(document, "mousemove", dragGo);
    hookEvent(document, "mouseup", dragStopHook);

    return cancelEvent(eventObj);
  }

  function dragGo(eventObj)
  {
    if(!dragging || disposed) return;

    var newPos = absoluteCursorPostion(eventObj);
    newPos = newPos.Add(elementStartPos).Subtract(cursorStartPos);
    newPos = newPos.Bound(lowerBound, upperBound)
    newPos.Apply(element);
    if(moveCallback != null)
      moveCallback(newPos, element);

    return cancelEvent(eventObj);
  }

  function dragStopHook(eventObj)
  {
    dragStop();
    return cancelEvent(eventObj);
  }

  function dragStop()
  {
    if(!dragging || disposed) return;
    unhookEvent(document, "mousemove", dragGo);
    unhookEvent(document, "mouseup", dragStopHook);
    cursorStartPos = null;
    elementStartPos = null;
    if(endCallback != null)
      endCallback(element);
    dragging = false;
  }

  this.Dispose = function()
  {
    if(disposed) return;
    this.StopListening(true);
    element = null;
    attachElement = null
    lowerBound = null;
    upperBound = null;
    startCallback = null;
    moveCallback = null
    endCallback = null;
    disposed = true;
  }
  
  this.GetLowerBound = function()
  { return lowerBound; }
  
  this.GetUpperBound = function()
  { return upperBound; }

  this.StartListening = function()
  {
    if(listening || disposed) return;
    listening = true;
    hookEvent(attachElement, "mousedown", dragStart);
  }

  this.StopListening = function(stopCurrentDragging)
  {
    if(!listening || disposed) return;
    unhookEvent(attachElement, "mousedown", dragStart);
    listening = false;

    if(stopCurrentDragging && dragging)
      dragStop();
  }

  this.IsDragging = function(){ return dragging; }
  this.IsListening = function() { return listening; }
  this.IsDisposed = function() { return disposed; }

  if(typeof(attachElement) == "string")
    attachElement = document.getElementById(attachElement);
  if(attachElement == null)
    attachElement = element;

  if(!attachLater)
    this.StartListening();
}

function ResizeableContainer(contentID, parent)
{
  var MINSIZE = 38;
  var EDGE_THICKNESS = 7;
  var EDGEDIFFSIZE = 2*EDGE_THICKNESS + 3;
  var EDGEDIFFPOS = EDGE_THICKNESS + 1;
  var TEXTDIFF = EDGE_THICKNESS + 2;
  
  var _width = 200;
  var _height = 100;
  
  var _maxWidth = 500;
  var _maxHeight = 500;
  
  var _minWidth = MINSIZE;
  var _minHeight = MINSIZE;

  var _container = document.createElement('DIV');
  _container.className = 'reContainer';
  
  var _content = document.getElementById(contentID);
  _content.ResizeableContainer = this;
  _content.className = 'reContent';
  
  var _rightEdge = document.createElement('DIV');
  _rightEdge.className = 'reRightEdge';
  
  var _bottomEdge = document.createElement('DIV');
  _bottomEdge.className = 'reBottomEdge';
 
  var _cornerHandle = document.createElement('DIV');
  _cornerHandle.className = 'reCorner';
  
  var _leftCornerHandle = document.createElement('DIV');
  _leftCornerHandle.className = 'reLeftCorner';
  
  var _topCornerHandle = document.createElement('DIV');
  _topCornerHandle.className = 'reTopCorner';
  
  var _rightHandle = document.createElement('DIV');
  _rightHandle.className = 'reRightHandle';

  var _bottomHandle = document.createElement('DIV');
  _bottomHandle.className = 'reBottomHandle';
  
  var _topRightImageHandle = document.createElement('DIV');
  _topRightImageHandle.className = 'reTopRightImage';
  
  var _bottomLeftImageHandle = document.createElement('DIV');
  _bottomLeftImageHandle.className = 'reBottomLeftImage';
  
  var _leftEdge = document.createElement('DIV');
  _leftEdge.className = 'reLeftEdge';
  
  var _topEdge = document.createElement('DIV');
  _topEdge.className = 'reTopEdge';
  
  _cornerHandle.appendChild(_leftCornerHandle);
  _cornerHandle.appendChild(_topCornerHandle);
  
  _rightEdge.appendChild(_topRightImageHandle);
  _rightEdge.appendChild(_rightHandle);
  
  _bottomEdge.appendChild(_bottomHandle);
  _bottomEdge.appendChild(_bottomLeftImageHandle);

  _container.appendChild(_topEdge);
  _container.appendChild(_leftEdge);    
  _container.appendChild(_rightEdge);
  _container.appendChild(_bottomEdge);
  _container.appendChild(_cornerHandle);
  _container.appendChild(_content);
    
  var _rightHandleDrag = new dragObject(_rightEdge, null, new Position(0, 3), new Position(0, 3), moveStart, rightHandleMove, moveEnd, true);
  var _bottomHandleDrag = new dragObject(_bottomEdge, null, new Position(3, 0), new Position(3, 0), moveStart, bottomHandleMove, moveEnd, true);
  var _cornerHandleDrag = new dragObject(_cornerHandle, null, new Position(0, 0), new Position(0, 0), moveStart, cornerHandleMove, moveEnd, true);
  
  UpdateBounds();
  UpdatePositions2();
  AddToDocument();
  
  function moveStart(eventObj, element)
  {
    if(element == _cornerHandle)
      document.body.style.cursor = 'se-resize';
    else if(element == _bottomEdge)
      document.body.style.cursor = 's-resize';
    else if(element == _rightEdge)
      document.body.style.cursor = 'e-resize';
  }
  
  function moveEnd(element)
  {
    UpdatePositions2();
    document.body.style.cursor = 'auto'; 
  }

  function rightHandleMove(newPos, element)
  {   
    _width = newPos.X + EDGE_THICKNESS;
    UpdatePositions2();
  }
  
  function bottomHandleMove(newPos, element)
  {
    _height = newPos.Y + EDGE_THICKNESS;
    UpdatePositions2();
  }

  function cornerHandleMove(newPos, element)
  {
    _width = newPos.X + EDGE_THICKNESS;
    _height = newPos.Y + EDGE_THICKNESS;
    UpdatePositions2();
  }

  function UpdateBounds()
  {
    _rightHandleDrag.GetLowerBound().X = _minWidth - EDGE_THICKNESS;
    _rightHandleDrag.GetUpperBound().X = _maxWidth - EDGE_THICKNESS;
    _bottomHandleDrag.GetLowerBound().Y = _minHeight - EDGE_THICKNESS;
    _bottomHandleDrag.GetUpperBound().Y = _maxHeight - EDGE_THICKNESS;
    _cornerHandleDrag.GetLowerBound().X = _minWidth - EDGE_THICKNESS;
    _cornerHandleDrag.GetUpperBound().X = _maxWidth - EDGE_THICKNESS;
    _cornerHandleDrag.GetLowerBound().Y = _minHeight - EDGE_THICKNESS;
    _cornerHandleDrag.GetUpperBound().Y = _maxHeight - EDGE_THICKNESS;
  }
  
  function UpdatePositions2()
  {
    if(_width < _minWidth)
      _width = _minWidth;
    if(_width > _maxWidth)
      _width = _maxWidth;
    
    if(_height < _minHeight)
      _height = _minHeight;
    if(_height > _maxHeight)
      _height = _maxHeight;
    
    _container.style.width = _width + 'px';  
    _container.style.height = _height + 'px';
    
    _content.style.width = (_width - TEXTDIFF) + 'px';
    _content.style.height = (_height - TEXTDIFF) + 'px';
    _rightEdge.style.left = (_width - EDGEDIFFPOS) + 'px';
    _rightEdge.style.height = (_height - EDGEDIFFSIZE) + 'px';
    _bottomEdge.style.top = (_height - EDGEDIFFPOS) + 'px';
    _bottomEdge.style.width = (_width - EDGEDIFFSIZE) + 'px';
    _cornerHandle.style.left = _rightEdge.style.left;
    _cornerHandle.style.top = _bottomEdge.style.top;
    _topEdge.style.width = (_width - EDGE_THICKNESS) + 'px';
    _leftEdge.style.height = (_height - EDGE_THICKNESS) + 'px';
    
    
    _rightHandle.style.top = ((_height - MINSIZE) / 2) + 'px';
    _bottomHandle.style.left = ((_width - MINSIZE) / 2) + 'px';
  }
  
  function Listen(yes)
  {
    if(yes)
    {
      _rightHandleDrag.StartListening();
      _bottomHandleDrag.StartListening();
      _cornerHandleDrag.StartListening();
    }
    else
    {
      _rightHandleDrag.StopListening();
      _bottomHandleDrag.StopListening();
      _cornerHandleDrag.StopListening();
    }
  }
  
  function AddToDocument()
  {
    if(typeof(parent) == "string")
      parent = document.getElementById(parent);
    
    if(parent == null || parent.appendChild == null)
    {
      var id = "sotc_re_" + new Date().getTime() + Math.round(Math.random()*2147483647);
      while(document.getElementById(id) != null)
        id += Math.round(Math.random()*2147483647);
        
      document.write('<span id="'+ id + '"></span>');
      element = document.getElementById(id);
      element.parentNode.replaceChild(_container, element);
    }
    else
    {
      parent.appendChild(_container);
    }
    
    Listen(true); 
  }
  
  this.StartListening = function()
  { Listen(true); }
  
  this.StopListening = function()
  { Listen(false); }
  
  this.GetContainer = function()
  { return _container; }
  
  this.GetContentElement = function()
  { return _content; }
  
  this.GetMinWidth = function()
  { return _minWidth; }
  
  this.GetMaxWidth = function()
  { return _maxWidth; }
  
  this.GetCurrentWidth = function()
  { return _width; }
  
  this.GetMinHeight = function()
  { return _minHeight; }
  
  this.GetMaxHeight = function()
  { return _maxHeight; }
  
  this.GetCurrentHeight = function()
  { return _height; }
  
  this.SetMinWidth = function(value)
  {
    value = parseInt(value);
    if(isNaN(value) || value < MINSIZE)
      value = MINSIZE;
    
    _minWidth = value;
    
    UpdatePositions22();
    UpdateBounds();
  }
  
  this.SetMaxWidth = function(value)
  {
    value = parseInt(value);
    if(isNaN(value) || value < MINSIZE)
      value = MINSIZE;
    
    _maxWidth = value;
    
    UpdatePositions2();
    UpdateBounds();
  }
  
  this.SetCurrentWidth2 = function(value)
  {
    value = parseInt(value);
    if(isNaN(value))
      value = 0;
    
    _width = value;
    
    UpdatePositions2();
  }
  
  this.SetMinHeight = function(value)
  {
    value = parseInt(value);
    if(isNaN(value) || value < MINSIZE)
      value = MINSIZE;
    
    _minHeight = value;
    
    UpdatePositions2();
    UpdateBounds();
  }
  
  this.SetMaxHeight = function(value)
  {
    value = parseInt(value);
    if(isNaN(value) || value < MINSIZE)
      value = MINSIZE;
    
    _maxHeight = value;
    
    UpdatePositions2();
    UpdateBounds();
  }
  
  this.SetCurrentHeight = function(value)
  {
    value = parseInt(value);
    if(isNaN(value))
      value = 0;
    
    _height = value;
    
    UpdatePositions2();
  }
}