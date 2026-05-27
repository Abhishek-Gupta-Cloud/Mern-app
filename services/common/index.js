function buildMongoUri({ user, password, host = 'mongo', port = 27017, db = 'mernapp', authSource = 'admin' } = {}) {
  if (user && password) {
    return `mongodb://${user}:${password}@${host}:${port}/${db}?authSource=${authSource}&retryWrites=true&w=majority`;
  }
  return `mongodb://${host}:${port}/${db}`;
}

function requireEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`${name} is required`);
  return v;
}

module.exports = { buildMongoUri, requireEnv };
