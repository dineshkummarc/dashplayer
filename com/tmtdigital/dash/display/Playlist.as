﻿/**
 * Playlist.as - See class description for information.
 *
 * Author - Travis Tidwell ( travist@tmtdigital.com )
 * License - General Public License ( GPL version 3 )
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see http://www.gnu.org/licenses/
 **/
package com.tmtdigital.dash.display
{
   import com.tmtdigital.dash.display.Skinable;
   import com.tmtdigital.dash.display.node.Teaser;
   import com.tmtdigital.dash.display.node.NodeBase;
   import com.tmtdigital.dash.display.PlaylistLinks;
   import com.tmtdigital.dash.display.Navigation;
   import com.tmtdigital.dash.events.DashEvent;
   import com.tmtdigital.dash.utils.Utils;
   import com.tmtdigital.dash.utils.LayoutManager; 
   import com.tmtdigital.dash.utils.Pager;
   import com.tmtdigital.dash.net.Gateway;
   import com.tmtdigital.dash.net.Service;       
   import com.tmtdigital.dash.display.media.MediaPlayer;
   import com.tmtdigital.dash.display.controls.ScrollRegion;
   import com.tmtdigital.dash.config.Params;

   import flash.events.*;
   import flash.display.*;
   import flash.geom.*;
   import flash.text.*;
   import flash.utils.*;

   /**
    * The Playlist class is the display object to show the Playlist of the media player
    */
   public class Playlist extends Skinable
   {
      /**
       * Constructor for the Playlist.
       *
       * @param skin - The skin to be used for this playlist.
       */      
      public function Playlist( _skin:MovieClip )
      {
         super( _skin );
      }

      /**
       * Called from the Skinable class to set the skin for all of the elements within this MovieClip.
       *
       * @param skin - The skin MovieClip for the playlist.
       */   
      public override function setSkin( _skin:MovieClip )
      {
         // Set the Skinable class first.
         super.setSkin(_skin);
         
         navigation = new Navigation( skin.navigation );
         links = new PlaylistLinks( skin.links );
         scrollRegion = new ScrollRegion( skin.scrollRegion );
         
         service = Service.GET_VIEW;
         selectedPage = 0;
         selectedIndex = 0;
			
         // Set up the pager.
         loaded = false;
         pager = new Pager( Params.flashVars.shuffle );
         pager.addEventListener( DashEvent.LOAD_PAGE, onPageLoad );
         pager.addEventListener( DashEvent.LOAD_INDEX, onIndexLoad );
         
         spinner = new Spinner( skin.loader, "playlist" );	
      }

      // Called when the pager tells us to load a given page.
      private function onPageLoad( event:DashEvent )
      {
         getPlaylist( playlistName );
      }
   
      // Called when the pager tells us to load a particular index. 
      private function onIndexLoad( event:DashEvent )
      {
         loadIndex( pager.currentIndex );
      }

      /**
       * Sets a vote within this playlist.
       *
       * @param nodeId - The node ID of the item in the playlist you would like to set.
       * @param vote - The vote object that you are using to set the vote to.
       */
      public function setVote( nodeId:Number, vote:Object )
      {
         if (nodeId) {
            var teaser:Teaser = getTeaser( nodeId );
            if( teaser ) {
               teaser.fields.voter.setVote( vote );
            }
         }			
      }

      /**
       * Loads a playlist given the playlist name.
       *
       * @param - The name of the playlist to load.
       */
      public function loadPlaylist( _playlistName:String = null )
      {
         // If they did not provide a playlist name, then we will try the FlashVars.
         if (! _playlistName) {
            _playlistName = Params.flashVars.playlist;
         }

         if ( _playlistName && skin ) {
            pager.pageLimit = Params.flashVars.pagelimit;
            pager.pageIndex = Params.flashVars.playlistpage;
            pager.currentIndex = Params.flashVars.playlistindex;
            if( pager.currentIndex > 0 ) {
               pager.loadState = "current";
            }

            playlistName = _playlistName;

            // Setup the links.
            links.loadLinks();

            // Reset our arguments array.
            resetArguments();

            // If there is a navigation bar, then we will want to load that here.
            if (navigation.skin) {
               navigation.loadNavigation();
            }

            // Get the playlist.
            getPlaylist( playlistName );
         }
      }

      /**
       * Gets the node at a given index.
       *
       * @param - The index in the playlist to get.
       *
       * @return - The teaser at that index.
       */
      public function getNode( index:uint ):Teaser
      {
         // Make sure the index is within our array size.
         if (index < scrollRegion.elements.length) {
            // Return the teaser at this index.
            return (scrollRegion.getItem(index) as Teaser);
         } else {
            // Otherwise return NULL.
            return null;
         }
      }
      
      // Gets a teaser given any node Id for any element within the playlist.
      private function getTeaser( nodeId:Number ) : Teaser
      {
         if( scrollRegion )
         {
            var i:Number = scrollRegion.elements.length;
            while( i-- ) {
               var teaser:Teaser = (scrollRegion.getItem(i) as Teaser);
               if( teaser.node && (teaser.node.nid == nodeId) ) {
                  return teaser;
               }
            }
         }
         return null;
      }

      /**
       * Returns the media object for the selected teaser.
       *
       * @return MediaPlayer - The media player object.
       */
      public function get media():MediaPlayer
      {
         return Params.flashVars.teaserplay ? teaserMedia : null;
      }

      /**
       * Loads any node within our playlist given the node Id.
       *
       * @param - The node object or Id of the node you would like to load.
       */
      public function loadNode( _node:* )
      {
         var node:Object = NodeBase.translateNode( _node );
         if ( node && node.nid ) {
            var teaser:Teaser = getTeaser( node.nid );
            if( teaser ) {
               teaser.onNodeLoad( teaser.node );
            }
            else {
               addNode( node );
            }
         }
      }

      /**
       * Loads the node for a given index.
       *
       * @param - The index you would like to load.
       */
      protected function loadIndex( index:uint )
      {
         // Get the teaser from this index.
         var teaser:Teaser = getNode(index);
         if (teaser) {
            // Select this teaser.
            selectTeaser( teaser );

            // Load the node.
            Gateway.loadNode( teaser.node, Params.flashVars.playlistonly );
         }
      }

      // Deselects all of the teasers.
      private function deSelectTeasers()
      {
         // Iterate through all the teasers and deselect them.
         var i:Number = scrollRegion.elements.length;
         while (i--)
         {
            var element:Teaser = (scrollRegion.getItem(i) as Teaser);
            element.setSelect( false );
         }
      }

      /**
       * Selects any given teaser, while deselects all other teasers.
       *
       * @param - The teaser you would like to select.
       */
      private function selectTeaser( teaser:Teaser )
      {
         // Deselect all teasers.
         deSelectTeasers();

         // Set this item to be visible in the scroll region.
         scrollRegion.setVisible( teaser.index );

         // Select this teaser.
         teaser.setSelect( true );
         
         // Set the current pager index.
         pager.currentIndex = teaser.index;
         
         // Save the selected page and index.
         selectedPage = pager.pageIndex;
         selectedIndex = pager.currentIndex;			
			
         // Store the media field for this selected teaser.
         if (teaser.fields) {
            teaserMedia = teaser.fields.media;
         }			
      }

      // Selects the active teaser.
      private function selectActiveTeaser()
      {
         if( pager.pageIndex == selectedPage ) {
            var teaser:Teaser = (scrollRegion.getItem(selectedIndex) as Teaser);
            if( teaser ) {
               teaser.setSelect( true );
            }
         }
      }

      /**
       * Get's called after our service returns with a playlist object for us to parse.
       *
       * @param playlist - The playlist object returned from our service call.
       */
      public function onPlaylistLoaded( _playlist:Object )
      {
         // Store our new playlist.
         playlist = _playlist;

         if (playlist) {
            // Set the number of pages.
            pager.setNumPages( playlist.total_rows );

            if (rootSkin.setNavBar is Function) {
               rootSkin.setNavBar( pager.hasNextPage, pager.hasPrevPage );
            }

            // Backwards compatibility
            playlist = playlist.hasOwnProperty("nodes") ? playlist.nodes : playlist;

            // Initialize and empty our Scroll Region.
            scrollRegion.initialize( Params.flashVars.autoscroll, Params.flashVars.vertical, Params.flashVars.teaserspace );
            scrollRegion.empty();
				
            //var startTime:uint=getTimer();
            
            // Add all of our teasers.
            addTeasers();

            //trace( getTimer()-startTime );

            // Setup the scroll region.
            scrollRegion.setupScrollRegion();

            // Hide our loader since we are done loading our playlist.
				spinner.visible = false;

            // Let our skin hook in here to do something.
            if (rootSkin.onPlaylistLoad is Function) {
               rootSkin.onPlaylistLoad( _playlist );
            }
         }
      }

      /**
       * Adds a single node to the playlist
       *
       * @param playlist - The node object to be added to our playlist
       */
      public function addNode( node:Object ) {
         if ( rootSkin.getTeaser is Function ) {			
            // Get the teaser skin from our skin.
            var teaserSkin:MovieClip = rootSkin.getTeaser();
            if (teaserSkin) {
               // Create a new teaser object.
               var teaser:Teaser = new Teaser( teaserSkin, scrollRegion.elements.length );
	
               // Theme the teaser.
               LayoutManager.themeTeaser( teaser.skin );
	
               // Add an event listener to trigger when the user clicks on the teaser.
               teaser.addEventListener( DashEvent.NODE_LOADED, eventHandler );
               teaser.addEventListener( DashEvent.TEASER_CLICK, eventHandler );
							
               // set the node object in the teaser.
               teaser.setNode( node );
	
               // Add the item to our scroll region.
               deSelectTeasers();					
               selectActiveTeaser();
               pager.setNumItems( 1 );
					
               // Set up the scroll region.
               scrollRegion.initialize( Params.flashVars.autoscroll, Params.flashVars.vertical, Params.flashVars.teaserspace );
               scrollRegion.empty();					
               scrollRegion.addItem( teaser, pager.pageLimit );
               scrollRegion.setupScrollRegion();
            }
         }
      }

      // Adds all of our teaser nodes to the scroll region.
      private function addTeasers()
      {
         // We only want to continue here if our skin has provided a routine for
         // us to get a new teaser MovieClip.
         if (rootSkin.getTeaser is Function) {
            var teaser:Teaser = null;
            
            // Iterate through all of our nodes in the playlist.
            for each ( var node:Object in playlist ) {
               
               // Get the teaser skin from our skin.
               var teaserSkin:MovieClip = rootSkin.getTeaser();
               if (teaserSkin) {
                  // Create a new teaser object.
                  teaser = new Teaser( teaserSkin, scrollRegion.elements.length );

                  // Set the page this teaser is on...
                  teaser.page = pager.pageIndex;

                  // Theme the teaser.
                  LayoutManager.themeTeaser( teaser.skin );

                  // Add an event listener to trigger when the user clicks on the teaser.
                  teaser.addEventListener( DashEvent.TEASER_CLICK, eventHandler );
                  
                  // set the node object in the teaser.
                  teaser.node = NodeBase.translateNode( node );

                  // Add the item to our scroll region.
                  scrollRegion.addItem( teaser, pager.pageLimit );
               }
            }
            
            if( teaser ) {
               deSelectTeasers();					
               selectActiveTeaser();
					
               if( !Params.flashVars.node ) {
                  // Add the node loaded handler to the last teaser.
                  teaser.addEventListener( DashEvent.NODE_LOADED, eventHandler );
               }
               
               // Now iterate back through our teasers and load the data.
               var numItems:Number = scrollRegion.elements.length;
               pager.setNumItems( numItems );					
               for( var i:Number = 0; i < numItems; i++ ) {
                  teaser = (scrollRegion.getItem(i) as Teaser);
                  if( teaser ) {
                     teaser.setNode( teaser.node );
                  }
               }					
            }
				
            // If they also provide a node, then we will want to load it last.
            if( Params.flashVars.node ) {
               // Load the node.
               Gateway.loadNode( Params.flashVars.node, Params.flashVars.playlistonly );
            }
         }
      }

      /**
       * Sets the filter for the playlist.
       *
       * @param - The argument filter to provide to our playlist.
       * @param - The argument index for our playlist.
       */
      public function setFilter( arg:String, index:int = 0 )
      {
         // Reset the pager index.
         pager.pageIndex = 0;
         links.selectLink( arg );
         resetArguments();
			
			if( arg != "all" ) {
				stuffArguments(index);
				playlistArgs[index] = arg;
			}

         // Get the new playlist with these arguments.
         getPlaylist( playlistName );
      }

      /**
       * Sets the playlist.
       *
       * @param - The message object used for the service.
       */
      public function setPlaylist( message:Object )
      {
         // Reset the current index.
         pager.currentIndex = 0;

         // If they provide a custom service.
         if( message.hasOwnProperty("service") ) {
            service = message.service;
         }

         // If they provide a custom playlist name.
         if( message.hasOwnProperty("playlistName") ) {
            playlistName = message.playlistName;
         }

         // If they provide the page limit.
         if( message.hasOwnProperty("pageLimit") ) {
            pager.pageLimit = message.pageLimit;
         }

         // If they provide the page index.
         if( message.hasOwnProperty("pageIndex") ) {
            pager.pageIndex = message.pageIndex;
         }
			
			// If they provide the arguments to use.
			if( message.hasOwnProperty("args") ) {
            playlistArgs = new Array();
            for each( var arg:String in message.args ) {
               playlistArgs.push(arg);
            }
         }
         
         // Get the playlist.
         getPlaylist( playlistName );
      }

      /**
       * Resets the arguments to the defaults.
       */
      private function resetArguments()
      {
         playlistArgs = new Array();
         var args:Object = Params.flashVars.arg;
         for each (var arg:String in args) {
            playlistArgs.push(arg);
         }
      }

      /**
       * Stuffs the playlist args array depending on what index they need to put into the args array.
       */
      private function stuffArguments( index:int )
      {
         if (index >= playlistArgs.length) {
            for( var i:Number = playlistArgs.length; i <= index; i++ ) ;
            {
               playlistArgs.push("*");
            }
         }
      }

      /**
       * Event handler for handling the teaser and link clicks.
       *
       * @param - The DashEvent that was dispatched.
       */
      private function eventHandler( e:DashEvent )
      {
         switch ( e.type ) {
            case DashEvent.TEASER_CLICK :
               loadIndex( e.target.index );
               break;
               
            case DashEvent.NODE_LOADED :
               e.target.removeEventListener( DashEvent.NODE_LOADED, eventHandler );
               if( !playlist ) {
                  spinner.visible = false;
                  pager.loadIndex();
               }
               else if( loaded || !Gateway.isNodeLoaded( Params.flashVars.playlistonly ) ) {
                  pager.loadIndex();
               }
               loaded = true;
               break;
         }
      }

      /**
       * Makes a service call to get the playlist provided all necessary arguments.
       *
       * @param - The name of the playlist you would like to get.
       */
      private function getPlaylist( _playlistName:String )
      {
         if (_playlistName) {
            spinner.visible = true;
            Service.call( service, onPlaylistLoaded, null, _playlistName, pager.pageLimit, pager.pageIndex, playlistArgs );
         }
      }

      /**
       * Called after the player is resized.
       */
      public function postResize()
      {
			spinner.postResize( scrollRegion.listMask.width, scrollRegion.listMask.height );

         if (scrollRegion) {
            scrollRegion.postResize();
         }
      }

      /**
       * The navigation display item.
       */
      public var navigation:Navigation;
      
      /**
       * The playlist links display item.
       */      
      public var links:PlaylistLinks;
      
      /**
       * The scroll region display item.
       */      
      public var scrollRegion:ScrollRegion;
      
      /**
       * The spinner display item.
       */       
      public var spinner:Spinner;
      
      /**
       * The playlist object, which is a list of all of our nodes.
       */      
      public var playlist:Object;
      
      /**
       * The pager object, which is used to keep track of the pagination of the playlist.
       */         
      public var pager:Pager;
      
      // Private variables.
      private var service:String;
      private var playlistName:String;
      private var playlistArgs:Array;
      private var loaded:Boolean;
      private var selectedPage:Number;
      private var selectedIndex:Number;
      private var teaserMedia:MediaPlayer;
   }
}

