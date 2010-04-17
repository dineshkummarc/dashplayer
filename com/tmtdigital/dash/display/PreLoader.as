﻿/** * Copyright 2008 - TMTDigital LLC * * Author:   Travis Tidwell (www.travistidwell.com) * Version:  1.0 * Date:     June 9th, 2008 * * Description:  Functionality for the menu section of the Dash Player. * **/package com.tmtdigital.dash.display{   import com.tmtdigital.dash.display.Skinable;   import com.tmtdigital.dash.config.Params;         import flash.text.*;   import flash.display.*;   import flash.events.*;   public class PreLoader extends Skinable   {      public function PreLoader( playerStage:Stage, _onLoaded:Function )      {         _stage = playerStage;			var _skinPath:String = "";         if( Params.flashVars.preloader ) {            _skinPath = Params.getRootPath();            _skinPath += "/plugins/preloaders/" + Params.flashVars.preloader + "/preloader.swf";         }         super( null, _skinPath, _onLoaded );      }      public override function getSkin( newSkin:MovieClip ) : MovieClip      {         if( rootSkin && (rootSkin.getPreLoader is Function) ) {            return rootSkin.getPreLoader();         }         return newSkin;               }		public override function setSkin( _skin:MovieClip )		{			super.setSkin( _skin );						if( skin ) {			   _stage.addChild( skin );			   postResize( _stage.stageWidth, _stage.stageHeight );			}		}      public function onProgress( event:ProgressEvent ):void      {         setPreLoader( Math.floor((event.bytesLoaded / event.bytesTotal) * 100) );            }      public function setPreLoader( percent:Number )      {         if( rootSkin && ( rootSkin.setPreLoader is Function ) ) {            rootSkin.setPreLoader( percent );         }      }      public function postResize( _width:Number, _height:Number )      {         if( skin ) {			   skin.x = ((_width - skin.width) / 2);			   skin.y = ((_height - skin.height) / 2);			}	   }	   	   private var _stage:Stage;   }}