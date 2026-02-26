/**
 * ScyllaDB Alternator Load Balancer - JavaScript
 * From https://github.com/scylladb/alternator-load-balancing/tree/master/javascript
 * Modified to accept optional credentials parameter.
 *
 * Usage:
 *   const AWS = require('aws-sdk');
 *   const alternator = require('./Alternator');
 *   alternator.init(AWS, 'https', 8000, ['node1.example.com', 'node2.example.com'], {
 *     accessKeyId: 'alternator',
 *     secretAccessKey: 'secret'
 *   });
 */
const http = require('http');
const https = require('https');
const dns = require('dns');

const FAKE_HOST = 'dog.scylladb.com';
exports.FAKE_HOST = FAKE_HOST;

let protocol;
let hostIdx = 0;
let hosts;
let port;
let done = false;
let updatePromise;
let enableBackgroundUpdates = true;

const agentOpts = { keepAlive: true };
const httpAgent = new http.Agent(agentOpts);
const httpsAgent = new https.Agent(agentOpts);

function setupAgent(agent) {
    const oldCreateConnection = agent.createConnection;
    agent.createConnection = function (options, callback = null) {
        options.lookup = function (hostname, options = null, callback) {
            if (hostname === FAKE_HOST) {
                if (!hosts || hosts.length === 0) {
                    return dns.lookup('127.0.0.1', options, callback);
                }
                const host = hosts[hostIdx % hosts.length];
                hostIdx = (hostIdx + 1) % hosts.length;
                return dns.lookup(host || hosts[0] || '127.0.0.1', options, callback);
            }
            return dns.lookup(hostname, options, callback);
        };
        return oldCreateConnection(options, callback);
    };
}

setupAgent(httpAgent);
setupAgent(httpsAgent);

exports.httpAgent = httpAgent;
exports.httpsAgent = httpsAgent;
exports.agent = httpAgent;

async function updateHosts() {
    if (done || !enableBackgroundUpdates) return;
    const proto = (protocol === 'https') ? https : http;
    try {
        await new Promise((resolve) => {
            const currentHost = hosts[hostIdx % hosts.length] || hosts[0] || '127.0.0.1';
            const req = proto.get(protocol + '://' + currentHost + ':' + port + '/localnodes', (resp) => {
                let data = '';
                resp.on('data', (chunk) => { data += chunk; });
                resp.on('end', () => {
                    try {
                        const payload = JSON.parse(data);
                        if (Array.isArray(payload) && payload.length > 0) hosts = payload;
                    } catch (e) { /* keep existing hosts */ }
                    resolve();
                });
            });
            req.on('error', () => resolve());
            req.setTimeout(5000, () => { req.destroy(); resolve(); });
        });
    } catch (e) { /* keep existing hosts */ }
    await new Promise(r => setTimeout(r, 1000));
    return updateHosts();
}

/**
 * Initialize Alternator load balancing.
 * @param {object} AWS - AWS SDK v2 instance
 * @param {string} initialProtocol - 'http' or 'https'
 * @param {number} initialPort - Alternator port (typically 8000)
 * @param {string[]} initialHosts - List of Alternator node hostnames
 * @param {object} [credentials] - Optional { accessKeyId, secretAccessKey }
 */
exports.init = function (AWS, initialProtocol, initialPort, initialHosts, credentials) {
    protocol = initialProtocol;
    hosts = initialHosts && initialHosts.length ? [...initialHosts] : ['127.0.0.1'];
    hostIdx = 0;
    port = initialPort;
    enableBackgroundUpdates = !hosts.every(h =>
        h === '127.0.0.1' || h === 'localhost' || (typeof h === 'string' && h.startsWith('127.'))
    );

    const agent = (initialProtocol === 'https') ? httpsAgent : httpAgent;
    exports.agent = agent;

    const creds = credentials && credentials.accessKeyId
        ? { accessKeyId: credentials.accessKeyId, secretAccessKey: credentials.secretAccessKey || '' }
        : { accessKeyId: '1', secretAccessKey: '1' };

    AWS.config.update({
        credentials: creds,
        region: 'us-east-1',
        endpoint: protocol + '://' + FAKE_HOST + ':' + initialPort,
        httpOptions: { agent }
    });

    done = false;
    if (enableBackgroundUpdates) {
        updatePromise = updateHosts().catch(e => console.error(e));
    }
};

exports.done = function () {
    done = true;
};
