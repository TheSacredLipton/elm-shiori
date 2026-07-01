import { serve as honoServe } from '@hono/node-server';
import { serveStatic } from '@hono/node-server/serve-static';
import chokidar from 'chokidar';
import { Hono } from 'hono';
import { WebSocketServer } from 'ws';
import { cyan } from './utils.js';

/**
 * @typedef {import('./config.js').ShioriJson} ShioriJson
 */

/**
 * Runs the development Hono server and WebSocket server.
 * @param {ShioriJson} shioriJson
 * @param {number} port
 * @param {function(): Promise<void>} startWatchersCallback
 * @returns {Promise<void>}
 */
export const runDevServer = async (shioriJson, port, startWatchersCallback) => {
  // WebSocket 接続クライアントの管理
  /** @type {Set<import('ws').WebSocket>} */
  const wsClients = new Set();

  chokidar.watch('elm-stuff/shiori/shiori.js').on('change', async () => {
    for (const client of wsClients) {
      if (client.readyState === 1) {
        // OPEN
        client.send('reload');
      }
    }
  });

  chokidar
    .watch('shiori.json', { ignoreInitial: true })
    .on('add', async () => startWatchersCallback())
    .on('change', async () => startWatchersCallback());

  // Hono アプリケーションの作成
  const app = new Hono();

  app.get('/shiori.js', serveStatic({ path: './elm-stuff/shiori/shiori.js' }));
  app.get('/shiori-logo.svg', serveStatic({ path: './elm-stuff/shiori/logo.svg' }));

  if (shioriJson?.assets) {
    app.get('/*', async (c, next) => {
      if (c.req.path === '/shiori.js' || c.req.path === '/shiori-logo.svg' || c.req.path === '/') {
        return next();
      }
      return serveStatic({ root: shioriJson.assets })(c, next);
    });
  }

  app.get('/', serveStatic({ path: './elm-stuff/shiori/index.html' }));
  app.notFound(async c => {
    const res = await serveStatic({ path: './elm-stuff/shiori/index.html' })(c, async () => {});
    return res || c.text('Not Found', 404);
  });

  // Hono アプリの起動
  const server = honoServe(
    {
      fetch: app.fetch,
      port: port
    },
    info => {
      console.log(cyan(`Running at http://localhost:${info.port}`));
    }
  );

  // WebSocket Server を Hono サーバーに統合
  // @ts-expect-error - honoServe returns ServerType which might mismatch with ws.WebSocketServer's server option.
  const wss = new WebSocketServer({ server });
  wss.on('connection', ws => {
    wsClients.add(ws);
    ws.on('close', () => {
      wsClients.delete(ws);
    });
  });
};
