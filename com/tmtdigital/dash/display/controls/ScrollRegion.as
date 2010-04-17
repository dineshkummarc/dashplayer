﻿/**
 * Copyright 2008 - TMTDigital LLC
 *
 * Author:   Travis Tidwell (www.travistidwell.com)
 * Version:  1.0
 * Date:     June 9th, 2008
 *
 * Description:  The ScrollRegion class is used to manage the scrolling
 * capabilities of the Playlist area of the player.
 *
 **/
 
package com.tmtdigital.dash.display.controls
{     
   import com.tmtdigital.dash.utils.Utils;
   import com.tmtdigital.dash.display.Skinable;
   import com.tmtdigital.dash.display.node.Teaser;
   import com.tmtdigital.dash.events.DashEvent;
   import com.tmtdigital.dash.display.controls.ScrollBar;
   import com.tmtdigital.dash.utils.Resizer;  
   import com.tmtdigital.dash.config.Params;  

   import flash.display.*;
   import flash.events.*;
   import flash.geom.*;
   import flash.utils.*;
   import fl.transitions.*;
   import fl.transitions.easing.*;

   public class ScrollRegion extends Skinable 
   {    
      public function ScrollRegion( _skin:MovieClip )
      {
         super( _skin ); 
      }    
   
      /**
       * Sets the skin of this object.
       *
       * @param - The skin object to set.
       */   
      public override function setSkin( _skin:MovieClip )
      {
         super.setSkin( _skin );
         
         list = skin.list;
         scrollBar = new ScrollBar( skin.scrollBar, setListPos );
         scrollBar.addEventListener( DashEvent.PREV, onPrevNext );
         scrollBar.addEventListener( DashEvent.NEXT, onPrevNext );
         scrollBar.addEventListener( DashEvent.STOP, onDragStop );
         listMask = skin.listMask;
         listBack = skin.listBack;				
         Utils.removeAllChildren( skin.list );			
         
            numColumns = 0;
         autoScrollSpeed = Params.flashVars.scrollspeed;
         magnify = Params.flashVars.magnify;
         magnifysize = (Math.PI / Params.flashVars.diameter);
         amplitude = (Params.flashVars.amplitude / 100);		
         currentAmplitude = 0;
         amplitudeIncrement = amplitude / 4;
         
         if( magnify ) {	
            maxMagnify = Math.acos(0) / magnifysize;	
         }
               
         elements = new Array(); 			
      }    
      
      public function postResize()
      {
         if( initialized ) {
            setupScrollRegion();
         }
      }
      
      public function initialize( _autoScroll:Boolean, _vertical:Boolean, _space:int = 0 )
      {
         autoScroll = _autoScroll;
         vertical = _vertical;
         space = _space;

         lastRect = new Rectangle(0,0,0,0);
         numRows = 0;
         numColumns = 0;
      
         _x = (_vertical) ? "x" : "y";
         _y = (_vertical) ? "y" : "x";
         _mouseX = (_vertical) ? "mouseX" : "mouseY";
         _mouseY = (_vertical) ? "mouseY" : "mouseX";
         _localY = (_vertical) ? "localY" : "localX";
         _width = (_vertical) ? "width" : "height";
         _height = (_vertical) ? "height" : "width";			
                  
         listTween = new Tween( list, _y, Strong.easeOut, list[_y], list[_y],  Resizer.tweenTime );
         listTween.addEventListener( TweenEvent.MOTION_FINISH, onDragStop );
         listTween.stop();
      }
      
      public function setupScrollRegion()
      {
         list.x = 0;
         list.y = 0;
         
         if( elements.length > 0 ) {
            rowLength = elements[0][_height];
            elementMid = new Point(	(elements[0].width / 2), (elements[0].height / 2) );
         }			
               
         var _listSize:Number = list[_height];
         if( magnify ) {
            _listSize += 2*amplitude*rowLength;
         }
         listMaskSize = listMask[_width];
         var _listMaskHeight:Number = listMask[_height];
                  
         shouldScroll = (_listSize > _listMaskHeight) ? true : false;
         scrollMid = (_listMaskHeight / 2);
                           
         scrollBar.setupScrollBar( _listSize, _listMaskHeight );			
         listLength = _listSize - _listMaskHeight;
         listRect = new Rectangle();
         listRect[_height] = listLength;
         
         listMaskRect = skin.listMask.getRect( skin.stage );
         
         skin.removeEventListener( MouseEvent.MOUSE_OVER, onScrollOver ); 				
         skin.addEventListener( MouseEvent.MOUSE_OVER, onScrollOver ); 				
         
         initialized = true;
      }      
       
      public function onResize()
      {
         if( initialized ) {
            setupScrollRegion();
         }
      }        

      /**
       * Returns an element in the scroll region list.
       */
      public function getItem( index:int )
      {
         return elements[index];
      }

      /**
       * Empty the scroll region list.
       */
      public function empty()
      {
         Utils.removeAllChildren( list );
         elements = new Array();
      }
      
      /**
       * Automatically positions the list to always show the given index.
       *
       * @param - The index you would like to set visible.
       */
      public function setVisible( index:Number )
      {
         // Cache the current list position.
         var listPos:Number = list[_y];
            
         // Make sure our index is within bounds.
         if( index < list.numChildren ) {
            // If the list item at that index is above the visible region, then move the list position to show it.
            if( -elements[index][_y] > list[_y] ) {
               listPos = -elements[index][_y];
            } else if( (elements[index][_y] + elements[index][_height]) > (-list[_y] + listMask[_height]) ) {
               listPos = -((elements[index][_y] + elements[index][_height]) - listMask[_height]);
            }
               
            // If there is a difference in position.
            if( listPos != list[_y] ) {
               // Set the list and handle positions.
               setListPos( listPos, true );
               scrollBar.setListPos( listPos, true );
            }
         }
      }
      
      /**
       * Adds an element to the list region.
       *
       * @param - The skinable element you would like to add.
       * @param - The limit for each page.
       */
      public function addItem( element:Skinable, pageLimit:int = 10 )
      {
         if( element ) {
            setNumElements( element, pageLimit );
            setElementPosition( element );
            list.addChild( element.skin );
            elements.push( element );   
         }
      }

      /**
       * Sets the number of elements in our list.
       *
       * @param - The skinable element you would like to add.
       * @param - The limit for each page.
       */
      private function setNumElements( element:Skinable, pageLimit:int ) 
      {
         if( !numRows ) {
            numColumns = Math.floor(listMask[_width] / element[_width]);				
            numRows = numColumns ? (pageLimit / numColumns) : pageLimit;
         }
      }

      /**
       * Sets the element position within our list.
       *
       * @param - The skinable element you would like to add.
       */
      private function setElementPosition( element:Skinable )
      {
         var spaceY:Number = vertical ? 0 : space;
         var spaceX:Number = vertical ? space : 0;
         
         // Determine if we should wrap...
         if( (list.numChildren % numRows) == 0 ) {
            element[_x] = lastRect[_x] = lastRect[_x] + lastRect[_width] + spaceX;
            element[_y] = lastRect[_y] = spaceY;
         } else {
            element[_y] = lastRect[_y] = lastRect[_y] + lastRect[_height] + spaceY;
            element[_x] = lastRect[_x];
         }
         
         lastRect.width = element.width;
         lastRect.height = element.height;				
      }
      
      /**
       * Timer event to see if we are within our list, and automatically scroll if we are.
       *
       * @param - The timer event.
       */		 
      private function onScrollEvent( e:Event ) : void
      {					
         if( listMaskRect.contains( skin.stage.mouseX, skin.stage.mouseY ) ) {
            var mousePos:Number = skin.stage[_mouseY] - listMaskRect[_y];
            
            if( magnify )  {
               // This will create an easing affect to the highest amplitude.
               currentAmplitude += amplitudeIncrement;
               currentAmplitude = (currentAmplitude > amplitude) ? amplitude : currentAmplitude;
               setMagnify( skin.listMask[_mouseX], mousePos, currentAmplitude );
            }
            
            if( autoScroll && shouldScroll ) {
               var delta:int = 0;
               var hyst:uint = 15;
               var scrollMax:uint = autoScrollSpeed;
               
               if( Math.abs(mousePos - scrollMid) > hyst ) {
                  // Find the delta.
                  delta = scrollMax * ((mousePos - scrollMid) / scrollMid);
                  
                  // Set the handle position.
                  scrollBar.setHandlePos((scrollBar.handlePos + delta), false );
                  
                  // Set the list position.
                  setListPos(scrollBar.getListPos(), false );
               }
            }
         } else {			
            if( magnify && (currentAmplitude > 0) ) {
               // This will create an easing affect to zero amplitude.
               currentAmplitude -= amplitudeIncrement;
               currentAmplitude = (currentAmplitude < 0) ? 0 : currentAmplitude;
               setMagnify( skin.listMask[_mouseX], skin.listMask[_mouseY], currentAmplitude );
            } else {				
               onScrollOut(null);
            }
         }
      }
       
      /**
       * This function will iterate through all the elements and perform a magnify function
       * to give the illusion that the playlist is being seen through a magnifying glass.  This 
       * is somewhat processor intensive.
       *
       * @param - The x mouse position.
       * @param - The y mouse position.
       * @param - The amplitude you would like to set this magnify too.
       */ 
      private function setMagnify( _mouseX:Number, _mouseY:Number, _amplitude:Number )
      {
         currentAmplitude = _amplitude;
         
         // Only continue if they have magnify set to true.
         var listX:Number = -list[_x] + _mouseX;
         var listY:Number = -list[_y] + _mouseY;
         
         // Initialize our variables.
         var dx:Number;
         var dy:Number;	
         var cosX:Number;
         var cosY:Number;
         var cos:Number;
         var scale:Number;
            
         // Iterate through all our elements.		
         for( var i:Number=0; i < elements.length; i++) {
            // Calculate the mouse y offset from the elements mid point.
            dy = listY - (elements[i][_y] + elementMid[_y]);
            
            // Calculate the amplitude of this element given that offset.
            cosY = (Math.abs(dy) < maxMagnify) ? Math.cos(dy*magnifysize) : 0;
            
            // Make sure that the amplitude is always greater than zero.
            cosY = cos = (cosY >= 0) ? cosY : 0;
            
            // If there are more than one column, then we can do the same for the x direction.
            if( numColumns > 1 ) {
               dx = listX - (elements[i][_x] + elementMid[_x]);					
               cosX = (Math.abs(dx) < maxMagnify) ? Math.cos(dx*magnifysize) : 0;
               cosX = (cosX >= 0) ? cosX : 0;
               cos = (cosX < cosY) ? cosX : cosY;
            }
            
            // Calculate the scale...
            scale = 1 + (_amplitude*cos);
            
            // Calculate the scale of this element
            elements[i].scaleX = elements[i].scaleY = scale;
            
            // If there is a next item, then we need to change it's y position...
            if( ((i+1) < elements.length) && (((i%numRows)+1) < numRows) ) {
               elements[i+1][_y] = elements[i][_y] + elements[i][_height];
            }						
   
            // If there is an element next to this one, then we need to change it's x position.
            if( (numColumns > 1) && ((i+numRows) < elements.length) ) {
               elements[i+numRows][_x] = elements[i][_x] + elements[i][_width];
            }
         } 	
      }
       
      private function onScrollOver( e:MouseEvent )
      {			
         if( !isOver ) {
            isOver = true;
            skin.addEventListener( Event.ENTER_FRAME, onScrollEvent );
            
            if( !magnify ) {
               skin.addEventListener( MouseEvent.MOUSE_OUT, onScrollOut );
            }
         }
      }
      
      private function onScrollOut( e:MouseEvent )
      {			
         if( isOver ) {
            isOver = false;		
            skin.removeEventListener( Event.ENTER_FRAME, onScrollEvent );
            
            if( !magnify ) {
               skin.removeEventListener( MouseEvent.MOUSE_OUT, onScrollOut );
            }
         }
      }		
      
      private function onPrevNext( e:DashEvent )
      {
         var listPosition:Number = list[_y];
         listPosition += (e.type == DashEvent.PREV) ? rowLength : -rowLength;
         setListPos( listPosition, true );
         scrollBar.setListPos( listPosition, true );
      }

      /**
       * Sets the list position.
       *
       * @param - The list poisiton in pixels.
       * @param - Boolean to indicate if we should tween this movement.
       */      
      private function setListPos( listPos:Number, tween:Boolean = false )
      {
         listPos = (listPos > 0) ? 0 : listPos;
         listPos = (listPos < -(list[_height] - rowLength)) ? -(list[_height] - rowLength) : listPos;
         
         if( tween ) {
            listTween.stop();
            listTween.begin = list[_y];
            listTween.finish = listPos;
            listTween.start();		         
         } else {
            list[_y] = listPos;
         }
      }		

      private function onDragStop(e:Object)
      {
         if( Params.flashVars.teaserplay && elements.length && (elements[0] is Teaser) ) {
            var element:Teaser = getMostVisibleElement();
            setVisible( element.index );
         }
      } 
      
      /**
       * Determine which element in the elements list is the most visible and return that element.
       */
      private function getMostVisibleElement() : Teaser
      {
         // Initialize our variable.
         var mostVisible:Teaser = null;
         var listY:Number = Math.abs(list[_y]);
         var previousArea:Number = 0;
         
         // Iterate through all of our elements.
         for each( var element:Teaser in elements ) {
            // Reset the areashown.
            var areaShown:Number = 0;
               
            // If the element is behind the viewable region.
            if( (element[_y] < listY) && ((element[_y] + element[_height]) > listY) ) {
               areaShown = (element[_y] + element[_height]) - listY;
            } else if( (listY <= element[_y]) && ((listY + listMask[_height]) > element[_y]) ) {
               areaShown = (listY + listMask[_height]) - element[_y];
            }
               
            // If this area is larger than the previous, then this is the most visible.
            if( areaShown > previousArea ) {
               mostVisible = element;
               previousArea = areaShown;
            }
         }
         
         // Return the most visible item.
         return mostVisible;
      }
      
      // *** FlashVars *** //
      public var autoScroll:Boolean = true;
      public var vertical:Boolean = true;
      
      public var list:Sprite;
      public var scrollBar:ScrollBar;
      public var listMask:Sprite;		
      public var listBack:Sprite;
      public var elements:Array;
      
      private var _x:String;
      private var _y:String;
      private var _mouseX:String;
      private var _mouseY:String;
      private var _localY:String;
      private var _width:String;
      private var _height:String;
      
      private var space:int = 0;
      private var initialized:Boolean = false;
      private var numRows:int = 0;
      private var lastRect:Rectangle;
      private var shouldScroll:Boolean;
      private var scrollMid:Number;
      
      private var listLength:Number;
      private var listRect:Rectangle;    
      private var listMaskRect:Rectangle; 

      private var rowLength:Number;
      private var numColumns:Number;

      private var autoScrollSpeed:Number;
      
      private var magnify:Boolean;
      private var amplitude:Number;
      private var magnifysize:Number;
      private var maxMagnify:Number;
      private var currentAmplitude:Number;
      private var amplitudeIncrement:Number;
      private var elementMid:Point;
      
      private var listTween:Tween;

      private var listMaskSize:Number;
      private var isOver:Boolean = false;
   }
}