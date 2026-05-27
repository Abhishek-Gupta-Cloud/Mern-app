const { validationResult } = require('express-validator');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({ message: errors.array().map((e) => e.msg).join('. ') });
  }
  next();
};

module.exports = validate;
