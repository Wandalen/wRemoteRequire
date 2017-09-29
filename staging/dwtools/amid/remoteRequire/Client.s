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

  }

  //

  function require( src )
  {
    var self = this;

    var con = new wConsequence().give();

    if( self.verbosity >= 1 )
    console.log( 'require : ', src, 'filePath : ', self.filePath, 'token: ', self.token );

    var requestData =
    {
      token : self.token,
      require : src
    }

    var advanced  = { method : 'POST', send : JSON.stringify( requestData ) };
    var responseData = _.fileProvider.fileRead({ filePath : 'require', advanced : advanced });
    var response = JSON.parse( responseData );
    if( !response.fail )
    {
      var require = RemoteRequire.requireMake( response );
      con.doThen( () => require() );
    }

    return con;
  }

  function requireMake( o )
  {
    var self = this;
    var _require = _.routineJoin({ filePath : o.filePath, token : o.token }, self.require );
    var require = _.routineMake({ code : o.code, prependingReturn : 0, externals : { require : _require }, usingStrict : 0 });
    return require;
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
  }

  // --
  // prototype
  // --

  var Proto =
  {

    init : init,

    require : require,
    requireMake : requireMake,

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