( function _RemoteRequireClient_s_() {

  'use strict';

  //

  let _ = wTools;
  let Parent = null;
  let Self = function wRemoteRequireClient( o )
  {
    return _.workpiece.construct( Self, this, arguments );
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
    if( RemoteRequire.exports.value[ data.token ] )
    {
      return RemoteRequire.exports.value[ data.token ];
    }

    if( self.token )
    {
      if( !RemoteRequire.parents.value[ self.token ] )
      RemoteRequire.parents.value[ self.token ] = [];

      RemoteRequire.parents.value[ self.token ].push( data.token );
    }

    var exports = {};
    RemoteRequire.exports.value[ data.token ] = exports;

    var imported = document.createElement('script');
    imported.type = "text/javascript";
    imported.token = data.token;
    imported.tokenParent = self.token;
    imported.filePath = data.filePath;
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

  //

  function _setup()
  {
    function _moduleGet()
    {
      var self = document.currentScript;

      if( !self.module )
      self.module =
      {
        exports : RemoteRequire.exports.value[ self.token ],
        parent : RemoteRequire.parents.value[ self.tokenParent ],
        isBrowser : true
      };

      return self.module;
    }

    function _requireGet()
    {
      let self = document.currentScript;

      if( !self.require )
      self.require = _.routineJoin
      ({
        token : self.token,
        script : self
        },
        require
      );

      return self.require;
    }

    Object.defineProperty( _global_, 'module', { get: _moduleGet } );
    Object.defineProperty( _global_, 'require', { get: _requireGet } );
  }

  //

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
    parents : _.define.own( {} ),
    setup : _setup
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
  // debugger
  Self.setup();
  // _global_[ 'module' ] = { isBrowser : true };
})();
