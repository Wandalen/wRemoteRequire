( function _RemoteRequireClient_s_() {

  'use strict';

  //

  var _ = wTools;
  var Parent = null;
  var Self = function wRemoteRequireClient( o )
  {
    if( !( this instanceof Self ) )
    if( o instanceof Self )
    return o;
    else
    return new( _.routineJoin( Self, Self, arguments ) );
    return Self.prototype.init.apply( this,arguments );
  }

  Self.nameShort = 'RemoteRequireClient';

  //

  function init( o )
  {
    var self = this;

    _.assert( arguments.length === 0 | arguments.length === 1 );

    if( o )
    self.copy( o )

    if( !self.remoteAdress )
    self.remoteAdress = 'http://localhost:3333';

    self._requestUrl = _.urlJoin( self.remoteAdress, 'require' );

    if( !self.map )
    self.map = {};

    if( !self.queue )
    self.queue = [ null ];
  }

  //

  function require( src )
  {
    var res;

    var self = this;

    // console.log( 'require : ', src )

    if( !self.currentPath )
    {
      var scripts = document.getElementsByTagName( "script" );
      var script =  scripts[ scripts.length - 1 ];
      var from = script.src || _.strRemoveBegin( script.baseURI, 'file://' );
    }
    else
    var from = self.currentPath;

    if( self.map[ src ] )
    {
      self.queue.push( self.currentPath );
      self.currentPath = self.map[ src ].realPath;

      try
      {
        res = self.map[ src ].module();
      }
      catch(err)
      {
      }

      self.currentPath = self.queue.pop();

      return res;
    }

    var obj = { from : from, file : src };
    var advanced  = { method : 'POST', send : JSON.stringify( obj ) };
    var response = _.fileProvider.fileRead({ filePath : 'require', advanced : advanced });
    response = JSON.parse( response );
    if( response.path )
    {
      var _module = _.routineMake({ code : response.file, prependingReturn : 0, usingStrict : 0 } );
      self.map[ src ] = { module : _module, realPath : response.path };
      self.queue.push( self.currentPath );
      self.currentPath = self.map[ src ].realPath;
      try
      {
        res = self.map[ src ].module();
      }
      catch(err)
      {
      }

      self.currentPath = self.queue.pop();
    }
    else
    {
      self.map[ src ] =
      {
         module : () => {},
         realPath : null
      };
    }

    return res;
  }

  // --
  // relationship
  // --

  var Composes =
  {
    remoteAdress : null,
    currentPath : null,
    queue : null,
    map : null,
    _requestUrl : null
  }

  var Restricts =
  {

  }

  var Statics =
  {
  }

  // --
  // prototype
  // --

  var Proto =
  {

    init : init,

    require : require,

    // relationships

    Composes : Composes,
    Restricts : Restricts,
    Statics : Statics,
  }

  //

  _.classMake
  ({
    cls : Self,
    parent : Parent,
    extend : Proto,
  });

  wCopyable.mixin( Self );

  _global_[ Self.name ] = wTools[ Self.nameShort ] = Self;
  _global_[ 'module' ] = { isBrowser : true };

})();