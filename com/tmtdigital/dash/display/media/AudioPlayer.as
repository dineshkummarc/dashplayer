﻿package com.tmtdigital.dash.display.media
{
   import com.tmtdigital.dash.config.Params;
   import com.tmtdigital.dash.events.DashEvent;
   import com.tmtdigital.dash.display.media.IMedia;

   import flash.display.*;
   import flash.events.*;
   import flash.media.*;
   import flash.utils.*;
   import flash.net.*;

   public class AudioPlayer extends Sound implements IMedia
   {
      public function AudioPlayer()
      {
         super();
         context = new SoundLoaderContext(Params.flashVars.bufferlength*1000,true);
         audioTimer = new Timer(100);
         audioTimer.addEventListener( TimerEvent.TIMER, timeHandler );
         audioTimer.stop();
      }

      public function connect( stream:String ) : void
      {
         SoundMixer.stopAll();
         dispatchEvent( new DashEvent( DashEvent.MEDIA_CONNECTED ) );
      }

      public function loadFile( file:String ) : void
      {
         dispatchEvent( new DashEvent( DashEvent.MEDIA_LOADING ) );
         _playing = false;
         _buffering = false;
         counter = 0;
         stop();

         removeEventListener( Event.COMPLETE, audioUpdate );
         removeEventListener( ProgressEvent.PROGRESS, audioUpdate );
         removeEventListener( Event.ID3, audioUpdate );

         addEventListener( ProgressEvent.PROGRESS, audioUpdate );
         addEventListener( Event.ID3, audioUpdate );
         addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);

         position = 0;
         _loaded = true;
         _loadedFile = file;

         var request:URLRequest=new URLRequest(file);
         if( !Params.flashVars.cache ) {
            request.requestHeaders.push( new URLRequestHeader("pragma", "no-cache") );
         }

         try {
            super.load( request, context );
            loadInterval = setInterval(loadHandler,150);
         } catch (error:Error) {
            _loaded = false;
            trace("Unable to load " + file);
         }
      }

      private function loadHandler():void {
         dispatchEvent( new DashEvent( DashEvent.MEDIA_PROGRESS ) );
         
         if(bytesLoaded == bytesTotal && bytesLoaded > 0) {
            clearInterval(loadInterval);
         }			
      }

      private function audioUpdate( e:Object ):void
      {
         switch ( e.type ) {
            case Event.ID3 :
               dispatchEvent( new DashEvent( DashEvent.MEDIA_READY ) );
               break;

            case Event.SOUND_COMPLETE :
               audioTimer.stop();
               dispatchEvent( new DashEvent( DashEvent.MEDIA_COMPLETE ) );
               break;
         }
      }

      private function ioErrorHandler(event:Event):void
      {
         _loaded = false;
         trace("ioErrorHandler: " + event);
      }

      public function set volume(vol:Number) : void
      {
         if (channel) {
            var transform:SoundTransform = channel.soundTransform;
            transform.volume = vol;
            channel.soundTransform = transform;
         }
      }

      private function timeHandler(e:TimerEvent)
      {
         dispatchEvent( new DashEvent( DashEvent.MEDIA_UPDATE ) );
      }

      private function stopChannel() : void
      {
         if ( channel ) {
            channel.stop();
         }
         SoundMixer.stopAll();
         audioTimer.stop();      
      }

      public function playFile( _file:String ) : void
      {
         _playing = true;
         stopChannel();
         audioTimer.start();
         channel = super.play(position);
         channel.removeEventListener( Event.SOUND_COMPLETE, audioUpdate );
         channel.addEventListener( Event.SOUND_COMPLETE, audioUpdate );
         dispatchEvent( new DashEvent( DashEvent.MEDIA_PLAYING ) );
      }

      public function pause() : void
      {
         _playing = false;
         position = channel.position;
         stopChannel();			
         dispatchEvent( new DashEvent( DashEvent.MEDIA_PAUSED ) );
      }

      public function stop() : void
      {
         _playing = false;
         position = 0;
         stopChannel();
         clearInterval(loadInterval);
         dispatchEvent( new DashEvent( DashEvent.MEDIA_STOPPED ) );
      }

      public function seek( pos:Number ) : void
      {
         if ( channel) {
            stopChannel();	
            channel = super.play((pos * 1000));
            audioTimer.start();					
            if( !_playing ) {
               pause();
            }
            channel.removeEventListener( Event.SOUND_COMPLETE, audioUpdate );
            channel.addEventListener( Event.SOUND_COMPLETE, audioUpdate );
         }
      }

      public function get totalTime():Number
      {
         return (( bytesLoaded < bytesTotal ) ? 240 : (length / 1000));
      }

      public function get playheadTime():Number
      {
         return (channel ? (channel.position / 1000) : 0);
      }

      public function get ratio():Number
      {
         return 0;
      }

      public function get type():String
      {
         return "audio";
      }
      
      public function get loaded():Boolean
      {
         return _loaded;
      }
      
      public function get loadedFile():String
      {
         return _loadedFile;
      }
      
      public function get playing() : Boolean
      {
         return _playing;
      }
      
      public function get buffering() : Boolean
      {
         return _buffering;
      }				

      private var channel:SoundChannel;
      private var context:SoundLoaderContext;
      private var loadInterval:Number;
      private var position:Number = 0;
      private var audioTimer:Timer;
      private var _playing:Boolean = false;	
      private var _buffering:Boolean = false;
      private var counter:Number;
      private var _loaded:Boolean = false;
      private var _loadedFile:String = "";		
   }
}