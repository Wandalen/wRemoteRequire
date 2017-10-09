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

    // var con = new wConsequence().give();

    if( self.verbosity >= 1 )
    console.log( 'require : ', src, '\nfrom : ', self.filePath, '\ntoken of parent: ', self.token, '\n' );

    var requestData =
    {
      token : self.token,
      require : src
    }

    var endPoint = self.endPoint ? self.endPoint : 'require';

    var advanced  = { method : 'POST', send : JSON.stringify( requestData ) };
    var responseData = _.fileProvider.fileRead({ filePath : endPoint, advanced : advanced });
    var response = JSON.parse( responseData );

    if( !response.fail )
    {
      var file = RemoteRequire.files[ response.token ];
      var module = {  exports : {}, parent : self.token };
      module.isBrowser = true;

      if( file )
      return RemoteRequire.cache[ response.token ].exports;
      else
      {
        RemoteRequire.cache[ response.token ] = module;
        var require = RemoteRequire.requireMake( response, module );
        require();
        return module.exports;
      }

    }

  }

  function requireMake( o, module )
  {
    var self = this;

    var _require = _.routineJoin({ filePath : o.filePath, token : o.token }, self.require );
    var require;

    if( self.counter < 1 )
    {
      // var routine = _.routineMake({ code : o.code, prependingReturn : 0, usingStrict : 0 });
      var code = '__launcher__._beforeRun( require ).doThen( () => { debugger;var routine = wTools.routineMake({ code : code, prependingReturn : 0, externals : { require : require, module : module }, usingStrict : 0 }); routine(); })'
      require = _.routineMake({ code : code, prependingReturn : 0, externals : { code : o.code, require : _require, module : module }, usingStrict : 0 });
    }
    else
    {
      require = _.routineMake({ code : o.code, prependingReturn : 0, externals : { require : _require,  module : module }, usingStrict : 0 });
    }

    self.counter += 1;
    RemoteRequire.files[ o.token ] = { require : require };

    return require;
  }

  //


  function resolve( src, returnResponse )
  {
    var self = this;

    var requestData =
    {
      resolve : src
    }

    var advanced  = { method : 'POST', send : JSON.stringify( requestData ) };
    var responseData = _.fileProvider.fileRead({ filePath : 'resolve', advanced : advanced });
    var response = JSON.parse( responseData );

    if( returnResponse )
    return response;

    if( !response.fail )
    {
      return response.filePath;
    }
    else
    {
      throw response.err;
    }

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
    files : {},
    cache : {},
    counter : 0
  }

  // --
  // prototype
  // --

  var Proto =
  {

    init : init,

    require : require,
    requireMake : requireMake,
    resolve : resolve,

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