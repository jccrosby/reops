package com.realeyes.osmf.plugins
{
	import com.realeyes.osmf.data.IDOverlayVO;
	import com.realeyes.osmf.elements.IDFingerprintElement;
	import com.realeyes.osmf.elements.IDOverlayElement;
	import com.realeyes.osmf.elements.IDWatermarkElement;
	import com.realeyes.osmf.elements.SkinContainerElement;
	import com.realeyes.osmf.elements.WatermarkProxyElement;
	import com.realeyes.osmf.events.DebugEvent;
	import com.realeyes.osmf.interfaces.IVideoShell;
	import com.realeyes.osmf.utils.PluginUtils;
	
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.text.TextFormat;
	
	import org.osmf.containers.MediaContainer;
	import org.osmf.elements.F4MElement;
	import org.osmf.elements.ProxyElement;
	import org.osmf.events.ContainerChangeEvent;
	import org.osmf.events.MediaElementEvent;
	import org.osmf.events.TimeEvent;
	import org.osmf.layout.HorizontalAlign;
	import org.osmf.layout.LayoutMetadata;
	import org.osmf.layout.ScaleMode;
	import org.osmf.layout.VerticalAlign;
	import org.osmf.media.MediaElement;
	import org.osmf.media.MediaFactoryItem;
	import org.osmf.media.MediaFactoryItemType;
	import org.osmf.media.MediaPlayer;
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.PluginInfo;
	import org.osmf.metadata.Metadata;
	import org.osmf.net.NetLoader;
	import org.osmf.traits.MediaTraitType;
	import org.osmf.traits.TimeTrait;
	
	public class IDOverlayPluginInfo extends PluginInfo
	{
		// Plugin Namespace -  
		static public const NAMESPACE:String = "com.realeyes.osmf.plugins.IDOverlayPluginInfo";
		static public const FINGERPRINT:String = "fingerprint";
		static public const WATERMARK:String = "watermark";
		
		protected var _currentElement:MediaElement;
		protected var _currentContainer:MediaContainer;
		protected var _idOverlayElement:IDOverlayElement;
		
		
		protected var idOverlayVO:IDOverlayVO;
		
		///////////////////////////////////////////////////
		// CONSTRUCTOR
		///////////////////////////////////////////////////
		
		public function IDOverlayPluginInfo( mediaFactoryItems:Vector.<MediaFactoryItem>=null, mediaElementCreationNotificationFunction:Function=null )
		{
			
			
			//pass along the default Vector of MediaFacttoryItems, and specify which notification function to use for refference plugin implementation
			super( mediaFactoryItems, elementCreatedNotification );
		}
		
		
		
		
		/**
		 * Called from super class when plugin has been initialized with the MediaFactory from which it was loaded.
		 *  
		 * @param resource	Provides acces to the Resource used to load the plugin and any associated meta data
		 * 
		 */	
		override public function initializePlugin( resource:MediaResourceBase ):void
		{
			
			
			debug( "IDOverlayPluginInfo - Initialized" );
			
			var metaData:Metadata = resource.getMetadataValue( NAMESPACE ) as Metadata;
			
			var type:String = metaData.getValue("type");
			var overlayID:String = metaData.getValue("overlayID");
			var separator:String = metaData.getValue("separator");
			var format:TextFormat = metaData.getValue("format") as TextFormat;
			var alpha:Number = Number(metaData.getValue("alpha"));
			
			
				
			idOverlayVO = new IDOverlayVO( type, overlayID, separator, format, alpha );
			
		}
		
		////////////////////////////////////////////////
		//REFFERENCE PLUGIN IMPLEMENTATION
		
		/**
		 *Called whenever a MediaElement is generated by the MediaFactory which the plugin was loaded from.
		 * This method will be called for any element that was created. It will be called for elements loaded before the plugin was loaded if they exist. 
		 * @param element
		 * 
		 */
		protected function elementCreatedNotification( element:MediaElement ):void 
		{
			debug( "Element Created: " + element);
			
			if( !(element is F4MElement) && !(element is ProxyElement && (element as ProxyElement).proxiedElement is F4MElement ) )
			{
				linkElementForControl( element )
			}
			
			/*if( !(element is F4MElement) )
			{
				linkElementForControl( element );
			}*/
			
		}
		
		
		protected function linkElementForControl( element:MediaElement ):void
		{
			if( _currentElement )
			{
				_currentElement.removeEventListener( ContainerChangeEvent.CONTAINER_CHANGE, _onContainerChange );
			}
			
			_currentElement = element;
			
			
			//listen for when the element is added to the container
			_currentElement.addEventListener( ContainerChangeEvent.CONTAINER_CHANGE, _onContainerChange, false, 0, true );
		}
		
		
		////////////////////////////////////////////////
		
		private function _addElements():void
		{
			if( !_idOverlayElement )
			{
				
				var overlayLayout:LayoutMetadata = new LayoutMetadata();
				
				switch( idOverlayVO.type )
				{
					case WATERMARK:
					{
						_idOverlayElement = new IDWatermarkElement( _currentContainer, idOverlayVO );
						
						
						/*overlayLayout.left = 0;
						overlayLayout.right = 0;
						overlayLayout.top = 0;
						overlayLayout.bottom = 0;*/
						//			overlayLayout.verticalAlign = VerticalAlign.MIDDLE;
						//			overlayLayout.horizontalAlign = HorizontalAlign.CENTER;
						//			overlayLayout.percentWidth = 100;
						//			overlayLayout.percentHeight = 100;
						//overlayLayout.scaleMode = ScaleMode.ZOOM;
						overlayLayout.x = (_currentContainer.width/2)
						overlayLayout.y = (_currentContainer.height/2)
						overlayLayout.index = 50;
						
						break;
					}
					case FINGERPRINT:
					{
						_idOverlayElement = new IDFingerprintElement( _currentContainer, idOverlayVO );
						overlayLayout.percentWidth = 100;
						overlayLayout.percentHeight = 100;
						overlayLayout.index = 50;
						break;
					}
				}
				
				
				_idOverlayElement.addMetadata( LayoutMetadata.LAYOUT_NAMESPACE, overlayLayout );
				
			}
			
			
			
			if( !_currentContainer.containsMediaElement( _idOverlayElement ) )
			{
				debug("ADD ID OVERLAY");
				_currentContainer.addMediaElement( _idOverlayElement );
	//			_currentContainer.parent.addChild( _idOverlayElement.sprite );
			}
		}
		
		private function _clearElements():void
		{
			if(_idOverlayElement && _currentContainer.containsMediaElement( _idOverlayElement ) )
			{
				debug("REMOVE ID OVERLAY");
				_currentContainer.removeMediaElement( _idOverlayElement );
			}
		}
		
		
		private function _onContainerChange( event:ContainerChangeEvent ):void
		{
			if( event.oldContainer )
			{	
				//clear the skin element 
				_clearElements();
			}	
			
			//if the element is being added (has a newContainer) 
			if( event.newContainer )
			{
				//get a refference to the actual container the element is being used in - THIS IS COOL!!!
				_currentContainer = event.newContainer as MediaContainer;
				
				
				
				if( _idOverlayElement && !_currentContainer.containsMediaElement( _idOverlayElement ) )
				{

					debug("--MOVE/ADD ID OVERLAY");
					//_skinElement.container = _currentContainer;

					_currentContainer.addMediaElement( _idOverlayElement );
				}
				else
				{
					_addElements();
				}
				/*if( _skinElement.controlBar ) //YES THIS IS A HACK - LEAVE ME ALONE (DH)
				{
				_skinElement.controlBar.currentState = "playing";
				}*/
			}
		}
		
	
		
		// ==================================================
		// Helper methods
		// ==================================================
		
		protected function debug( msg:String ):void 
		{
			trace( msg );
			/*if( _vidShell )
			{
				_vidShell.debug( msg );
			}*/
		}
	}
}