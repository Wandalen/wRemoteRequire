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

    self._requestUrl = _.uri.uriJoin( self.remoteAdress, 'require' );

  }

  //

  function require( src )
  {
    var self = this;
    let remoteRequireExports = RemoteRequire.exports.value;

    // debugger
    // console.log( "require:", src, "from token:", self.token );

    var urlBase = _.uri.uriJoin( window.location.href,'require?package='+src );
    var url;

    if( self.local )
    {
      url =  urlBase+'&local=1';
    }
    else
    {
      url =  urlBase+'&token='+self.token;
    }

    var advanced  = { method : 'GET' };
    var responseData = _.fileProvider.fileRead({ filePath : url, advanced : advanced });

    var data = JSON.parse( responseData );
    if( data.fail )
    {
      throw _.err( 'Can not require: ', src )
      return;
    }

    // debugger
    if( remoteRequireExports[ data.token ] )
    {
      return remoteRequireExports[ data.token ];
    }

    if( self.token )
    {
      if( !RemoteRequire.parents.value[ self.token ] )
      RemoteRequire.parents.value[ self.token ] = [];

      RemoteRequire.parents.value[ self.token ].push( data.token );
    }

    debugger
    var exports = {};
    remoteRequireExports[ data.token ] = exports;

    var imported = document.createElement('script');
    imported.type = "text/javascript";
    imported.defer = true;
    imported.async = false;
    imported.appendChild( document.createTextNode( data.code ) )

    if( self.script )
    document.head.insertBefore( imported, self.script );
    else
    document.head.appendChild(imported);


    return exports;
  }

  //

  var requireLocal = _.routineJoin({ local : 1}, require );

  //

  function resolve( src )
  {
    var self = this;

    // debugger

    var url = _.uri.uriJoin( window.location.href, 'resolve?package='+src+'&fromInclude=1' );

    var advanced  = { method : 'GET' };
    var responseData = _.fileProvider.fileRead({ filePath : url, advanced : advanced });

    var data = JSON.parse( responseData );
    if( data.fail )
    throw "Can't resolve " + src;

    return data.filePath;
  }

  // --
  // relationship
  // --

  var Composes =
  {
    remoteAdress : null,
    verbosity : 1
  }

  var Restricts =
  {
    _requestUrl : null,
  }

  var Statics =
  {
    exports : _.define.own( {} ),
    parents : _.define.own( {} )
  }

  // --
  // prototype
  // --

  var Proto =
  {

    init : init,

    require : require,
    resolve : resolve,

    requireLocal : requireLocal,

    // relationships

    Composes : Composes,
    Restricts : Restricts,
    Statics : Statics,
  }

  //

  _.classDeclare
  ({
    cls : Self,
    parent : Parent,
    extend : Proto,
  });

  wCopyable.mixin( Self );

  _global_[ Self.name ] = wTools[ Self.nameShort ] = Self;
  _global_[ 'module' ] = { isBrowser : true };
})();