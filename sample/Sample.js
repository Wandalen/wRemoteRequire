require( 'wremoterequire' );
var _ = wTools;
var express = require( 'express' );
var app = express();
var server = require( 'http' ).createServer( app );
var remoteRequire = new wRemoteRequireServer
({
  app : app,
  verbosity : 5,
  rootDir : __dirname
});
remoteRequire.start();

var modules = _.pathJoin( _.pathResolve( __dirname, '../' ), 'node_modules' );
var staging = _.pathJoin( _.pathResolve( __dirname, '../' ), 'staging' );

app.use( '/modules', express.static( modules ));
app.use( '/staging', express.static( staging ));

app.get( '/', function ( req, res )
{
  res.sendFile( _.pathJoin( __dirname, 'Sample.html' ) );
});

server.listen( 8080, function ()
{
  _.shell( 'open http://localhost:8080' );
});
