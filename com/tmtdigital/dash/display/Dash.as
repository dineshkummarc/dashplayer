﻿/** * Dash.as - See class description for information. * * Author - Travis Tidwell ( travist@tmtdigital.com ) * License - General Public License ( GPL version 3 ) * * This program is free software; you can redistribute it and/or modify * it under the terms of the GNU General Public License as published by * the Free Software Foundation; either version 3 of the License, or * (at your option) any later version. *  * This program is distributed in the hope that it will be useful, * but WITHOUT ANY WARRANTY; without even the implied warranty of * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the * GNU General Public License for more details. *  * You should have received a copy of the GNU General Public License * along with this program. If not, see http://www.gnu.org/licenses/ **/package com.tmtdigital.dash.display{   import com.tmtdigital.dash.DashPlayer;   import com.tmtdigital.dash.display.Skinable;	import com.tmtdigital.dash.display.Playlist;	import com.tmtdigital.dash.display.node.Node;   import com.tmtdigital.dash.utils.Utils;   import com.tmtdigital.dash.utils.Resizer;   import com.tmtdigital.dash.utils.LayoutManager;   import com.tmtdigital.dash.config.Params;   import com.tmtdigital.dash.net.Gateway;   import com.tmtdigital.dash.net.Service;      import com.tmtdigital.dash.display.media.MediaPlayer;   import flash.display.*;   import flash.events.*;   import flash.net.*;   import flash.geom.*;   /**    * This is the base display element within the Dash Media Player.  It is the element    * which contains the node and playlist display items.    */   public class Dash extends Skinable   {      /**       * Constructor for the Dash Media Player.       *       * @param skinName - The name of the skin which you would like to load.       * @param onLoaded - The callback function when the skin is finished loading.       * @param progress - The callback function to update the load process of the skin.       */         public function Dash( skinName:String, _onLoaded:Function, _progress:Function )      {         progress = _progress;         super( null, getSkinURL( skinName ), _onLoaded );      }      /**       * API to replace the old skin and load a new one.       *       * @param skinName - The name of the skin which you would like to load.       */         public function loadNewSkin( skinName:String )      {         super.loadSkin( null, getSkinURL( skinName ) );      }      /**       * Called from the Skinable class to set the skin for all of the elements within this MovieClip.       *       * @param skin - The skin MovieClip for this element.       */         public override function setSkin( _skin:MovieClip )      {         super.setSkin( _skin );                  if( skin.getConfigInfo is Function ) {            Params.loadConfig( skin.getConfigInfo(), false );         }         if( skin.getTweenFunction is Function ) {            Resizer.tweenFunction = skin.getTweenFunction();         }         if( skin.getLayoutInfo is Function ) {            LayoutManager.loadLayout( skin.getLayoutInfo() );         }         if( Params.flashVars.node && !Params.flashVars.playlist ) {            Params.flashVars.disableplaylist = true;         }                           node = new Node( skin.dash.node );         playlist = new Playlist( skin.dash.playlist );                  if( skin.initialize is Function ) {            skin.initialize( DashPlayer, Service, Resizer, Utils, LayoutManager, Params.flashVars, Gateway );         }                           hideShow();			         Resizer.preResize = preResize;         Resizer.postResize = postResize;	        }      /**       * Loads all of the content into the Playlist and the Node.       */       public function loadContent()      {         if ( _loadContent ) {            if ( !Params.flashVars.playlistonly && !Params.flashVars.playlist ) {               loadNode(null);            }            if ( !Params.flashVars.disableplaylist && playlist ) {               playlist.loadPlaylist();            }         }      }      /**       * Initialize function that will hide or show certain elements depending on the configuration provided       * to this player.       */       public function hideShow() : void      {         maximize( !Params.showPlaylist, false );         if( node ) {            node.hideShow();         }      }      /**       * Called before the player resizes.  This gives everyone a chance to perform certain tasks before the       * player is resized.       */       public function preResize()      {         DashPlayer.setAutoHide();               if( node ) {            node.preResize();         }      }      /**       * Called after the player resizes.  This gives everyone a chance to perform certain tasks after the        * player is resized.       */       public function postResize()      {         if( skin ) {            if( node.skin ) {               node.postResize();            }            if( playlist.skin ) {               playlist.postResize();            }            if( skin.onResize is Function ) {               skin.onResize();            }         }      }      /**       * Loads a node into the Node element.       *		 * @param node - A variable used to tell the player which node to load.  This variable can either be a 		 * number, which would indicate the Node ID of the node you would like to load or it can be an object, which		 * would be the node data in object form ( which would skip the load ).       */       public function loadNode( _node:* )      {         if( Params.flashVars.teaserplay && playlist && playlist.skin ) {            playlist.loadNode( _node );         }         else if( node && node.skin ) {            node.loadNode( _node );         }      }      /**       * Loads and display's the logo for both the node and playlist.       */       public function loadLogo()      {         if( node && node.fields ) {            node.fields.loadLogo();         }         if( playlist && playlist.navigation ) {            playlist.navigation.loadLogo();         }			      }      /**       * Used to maximize the player ( hide the playlist ).       *       * @param on - Boolean to indicate if you would like to maximize the player ( true - hide the playlist, false - show the playlist )		 * @param tween - Boolean to indicate if you would like to tween the playlist hide/show movement.       */       public function maximize( on:Boolean, tween:Boolean = true )      {         if ( skin && (skin.maximize is Function) && (maximized != on) ) {            maximized = on;            skin.maximize( on, tween );         }      }      /**       * Gets the media player object.       *       * @return MediaPlayer - The media player object.       */      public function get media() : MediaPlayer      {         if( Params.flashVars.teaserplay ) {            return playlist.media;         }         else {            return node.fields.media;         }      }      /**       * Creates the skin loader.  We need to override this here since we would like to provide a progress callback that is        * called as the skin is loaded.       */      public override function createLoader()      {         super.createLoader();         if (progress is Function) {            swfLoader.contentLoaderInfo.addEventListener( ProgressEvent.PROGRESS, progress );         }               }      /**       * Helper function to get the URL of the skin.       *       * @param skinName - The name of the skin.       * @return String - The full URL of the skin.       */      private function getSkinURL( skinName:String ) : String      {         var skinURL:String = Params.getRootPath();         var playlistSkin:String = Params.flashVars.playlistskin + ".swf";         var controlBarSkin:String = Params.flashVars.controlbarskin + ".swf";         var skinFile:String = "skin.swf";         if (Params.flashVars.playlistonly) {            skinFile = playlistSkin;         }         else if ( Params.flashVars.controlbaronly ) {            skinFile = controlBarSkin;         }         skinURL += "/skins/" + skinName + "/" + skinFile;                  return skinURL;            }      /**       * The Node object.       */      public var node:Node;            /**       * The Playlist object.       */            public var playlist:Playlist;            // Private variables.      private var maximized:Boolean = false;        private var _loadContent:Boolean = true;                private var progress:Function;        }}