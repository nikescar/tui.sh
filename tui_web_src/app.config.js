import { defineConfig } from "@solidjs/start/config";

console.log("get config here");

export default defineConfig({
  server: {
    // solidjs server
    static: true,
    prerender: {
      // routes: ['/','/file','/ip','/dns','/app'], // array of routes
      crawlLinks: true, // automatic route detection based on urls
    },
  },
  vite: {
    // vite options
    // plugins: [{ src: "apexcharts/dist/apexcharts.esm.js", mode: "server" }],
    ssr: {
      noExternal: ["apexcharts"],
    },
    server: {
      // https://vitejs.dev/config/server-options
      proxy: {
        // string shorthand: http://localhost:5173/foo -> http://localhost:4567/foo
        "/var": "http://127.0.0.1:58080",
        "/etc": "http://127.0.0.1:58080",
        "/index.yaml": "http://127.0.0.1:58080",
        "/dummy": "http://127.0.0.1:58080",
        // "/tnet": "http://localhost:58080",
        // with options: http://localhost:5173/api/bar-> http://example.com/bar
        // '/api': {
        //   target: 'http://127.0.0.1:58080',
        //   changeOrigin: true,
        //   rewrite: (path) => path.replace(/^\/api/, ''),
        // },
        // with RegEx: http://localhost:5173/fallback/ -> http://example.com/
        "^/fallback/.*": {
          target: "http://127.0.0.1:58080",
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/fallback/, ""),
        },
        // Using the proxy instance
        // '/api': {
        //   target: 'http://127.0.0.1/58080',
        //   changeOrigin: true,
        //   configure: (proxy, options) => {
        //     // proxy will be an instance of 'http-proxy'
        //   },
        // },
        // Proxying websockets or socket.io: ws://localhost:5173/socket.io -> ws://localhost:5174/socket.io
        //'/socket.io': {
        //  target: 'ws://localhost:5174',
        //  ws: true,
        //},
      },
    },
  },
});
