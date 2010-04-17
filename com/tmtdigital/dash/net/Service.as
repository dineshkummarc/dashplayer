﻿/**
 * Copyright 2008 - TMTDigital LLC
 *
 * Author:   Travis Tidwell (www.travistidwell.com)
 * Version:  1.0
 * Date:     June 9th, 2008
 *
 * Description:  The Service class is responsible for interfacing with any external
 * data delivery system, whether it be an external CMS or XML Playlist.
 *
 **/

package com.tmtdigital.dash.net
{
   import com.tmtdigital.dash.DashPlayer;	
   import com.tmtdigital.dash.net.DrupalService;
   import com.tmtdigital.dash.utils.Utils;
   import com.tmtdigital.dash.utils.xml.XMLParser;
   import com.tmtdigital.dash.config.Params;
   import com.tmtdigital.dash.display.Skinable;
   
   import flash.net.*;
   import flash.events.*;
   import flash.display.*;

   public class Service
   {
      public static const SYSTEM_CONNECT:String = "connect";
      public static const SYSTEM_MAIL:String = "mail";
      public static const NODE_LOAD:String = "nodeLoad";
      public static const GET_VERSION:String = "getVersion";
      public static const GET_VIEW:String = "getView";
      public static const GET_VOTE:String = "getVote";
      public static const SET_VOTE:String = "setVote";
      public static const GET_USER_VOTE:String = "getUserVote";
      public static const DELETE_VOTE:String = "deleteVote";
      public static const ADD_TAG:String = "addTag";
      public static const INCREMENT_NODE_COUNTER:String = "incrementCounter";
      public static const SET_FAVORITE:String = "setFavorite";
      public static const DELETE_FAVORITE:String = "deleteFavorite";
      public static const IS_FAVORITE:String = "isFavorite";
      public static const USER_LOGIN:String = "login";
      public static const USER_LOGOUT:String = "logout";
      public static const AD_CLICK:String = "adClick";
      public static const GET_AD:String = "getAd"; 
      public static const SET_USER_STATUS:String = "setUserStatus";

      public static function connect( _onConnected:Function )
      {
         files = new Array();
         callQueue = new Array();	
         onConnected = _onConnected;
			
         loadFile( {path:Params.flashVars.image} );
         loadFile( {path:Params.flashVars.intro, mediaclass:"intro"} ); 
         loadFile( {path:Params.flashVars.commercial, mediaclass:"commercial"} );
         loadFile( {path:Params.flashVars.prereel, mediaclass:"prereel"} ); 
         loadFile( {path:Params.flashVars.postreel, mediaclass:"postreel"} ); 
         
         if( loadFile( { path:Params.flashVars.file } ) ) {
            Params.flashVars.disableplaylist = true;
            Params.flashVars.showinfo = false;
         }
      
         var servicePath:String = "";
			
         if( Params.flashVars.service ) {
            servicePath = Params.getRootPath();
            servicePath += "/plugins/services/" + Params.flashVars.service + "/service.swf";
            service = new Skinable( null, servicePath, onServiceLoaded );
         }
         else {
            // Use Drupal by default...
            drupal = new DrupalService( );
            drupal.connectToGateway( onReady );
            onConnected();
         }
      }

      private static function onServiceLoaded()
      {
         if( service && service.rootSkin && (service.rootSkin.connect is Function) ) {
            service.rootSkin.connect( Params, Service, onReady );
         }
			
         onConnected();
      }

      private static function loadFile( mediaFile:Object ) 
      {
         var path:String = mediaFile.path;
         if( mediaFile.path ) {
            mediaFile = Utils.getMediaFile(mediaFile);
            if (mediaFile) {
               files.push( mediaFile );
               return true;
            } else {
               playlistMode = true;
               Params.flashVars.playlist = "dashplaylist";
               Utils.loadXML( path, onPlaylistLoad, onLoadError );
               return false;
            }
         }
         return false;			
      }

      public static function login( username:String, password:String, onLogin:Function, onLoginFailed:Function )
      {
         if( drupal ) {
            drupal.login( username, password, onLogin, onLoginFailed );
         } else if( service && service.rootSkin && (service.rootSkin.login is Function) ) {
            service.rootSkin.login( username, password, onLogin, onLoginFailed );
         }		
      }

      public static function logout( onLogout:Function, onLogoutFailed:Function )
      {
         if( drupal ) {
            drupal.logout( onLogout, onLogoutFailed );
         } else if( service && service.rootSkin && (service.rootSkin.login is Function) ) {
            service.rootSkin.logout( onLogout, onLogoutFailed );
         }	
      }

      /**
       * Called when an error occured loading the XML file.
       *
       * @param - The event object.
       */
      protected static function onLoadError( event:Object )
      {
         trace("An error occured when loading the XML playlist");
      }

      /**
       * Gets the current user logged into this player.
       *
       * @return - The user object.
       */
      public static function get user():Object
      {
         if( drupal ) {
            return drupal.user;
         } else if( service && service.rootSkin && (service.rootSkin.getUser is Function) ) {
            return service.rootSkin.getUser();
         } else {
            return null;
         }
      }

      public static function set user( newUser:Object ):void
      {
         if( drupal ) {
            drupal.user = newUser;
         } else if( service && service.rootSkin && (service.rootSkin.setUser is Function) ) {
            service.rootSkin.setUser( newUser );
         }
      }

      /**
       * A call made to our service.  This is how the rest of the system extracts data from external sources.
       *
       * @param - The actual command for this call.
       * @param - The callback for a successful call.
       * @param - The callback for a non-successful call.
       * @param - All the arguments used for this function call.
       */
      public static function call( command:String, onSuccess:Function, onFailed:Function, ... args )
      {
         var makeCall:Boolean = true;
         var message:Object = new Object();
         message.command = command;
         message.onSuccess = onSuccess;
         message.onFailed = onFailed;
         message.args = args;			
			
         if( DashPlayer.skin && (DashPlayer.skin.serviceCall is Function) ) {
            makeCall = DashPlayer.skin.serviceCall( message );
         }
			
         if( makeCall && !serviceCall( message ) ) {
            // Queue it up until we are ready.
            callQueue.push( message );         
         }
      }

      public static function serviceCall( message:Object ) : Boolean
      {
         if ( playlistMode && ( message.command == GET_VIEW ) ) {
            return dashCall( message.command, message.onSuccess, message.args );
         } else if( drupal ) {
            return drupal.serviceCall( message );
         } else if( service && service.rootSkin && (service.rootSkin.serviceCall is Function) ) {
            return service.rootSkin.serviceCall( message );
         }
         
         return true;
      }

      /**
       * Called when an external XML playlist file has been loaded.
       *
       * @param - The event object.
       */
      private static function onPlaylistLoad( e:Event )
      {
         parsePlaylist( new XML(e.target.data) );
      }

      /**
       * Translates and parses the XML data and stores it in our common data structure.
       *
       * @param - The actual XML code from the playlist that was just loaded.
       */
      private static function parsePlaylist( xml:XML )
      {
         playlistMode = XMLParser.parse( xml );
         onReady();
      }

      private static function onReady()
      {
         // Process all of the callQueues.
         for each( var message:Object in callQueue ) {
            serviceCall( message );
         }      
      }

      /**
       * A common service call translator.  This function will take the commands given
       * and then route them to the proper function call.
       *
       * @param - The command given in our service call.
       * @param - The on success callback function.
       * @param - The arguements passed to our service call.
       */
      private static function dashCall( command:String, onSuccess:Function, args:Array ) : Boolean
      {
         if( XMLParser.isReady() ) {
            switch ( command ) {
               case GET_VIEW :
                  onSuccess( XMLParser.getPlaylist( args[1], args[2] ));
                  break;
            }
            
            return true;
         }
         else {
            return false;
         }
      }

      // External Service SWF file.
      public static var service:Skinable;
		
      private static var drupal:DrupalService;
      private static var playlistMode:Boolean = false;
      private static var onConnected:Function;
      private static var callQueue:Array;      
      public static var files:Array;	
   }
}