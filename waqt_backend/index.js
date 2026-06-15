const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
const multer = require('multer');

const app = express();
const PORT = 3000;

// Setup image upload storage directory pointing to the CI4 public uploads
const uploadDir = path.join(__dirname, '..', 'waqt_ci4', 'public', 'uploads', 'posts');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = crypto.randomBytes(8).toString('hex');
    const ext = path.extname(file.originalname);
    cb(null, `${Date.now()}-${uniqueSuffix}${ext}`);
  }
});
const upload = multer({ storage: storage });

app.use(express.json());
app.use(cors());
app.use('/uploads', express.static(path.join(__dirname, '..', 'waqt_ci4', 'public', 'uploads')));

// Initialize SQLite database
const dbPath = path.join(__dirname, 'server_waqt.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error opening database:', err.message);
  } else {
    console.log('Connected to SQLite server database.');
    db.run("PRAGMA foreign_keys = ON");
    initializeDatabase();
  }
});

// Create tables
function initializeDatabase() {
  // 1. Users Table
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      session_token TEXT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // 2. Community Posts Table
  db.run(`
    CREATE TABLE IF NOT EXISTS community_posts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      post_type TEXT NOT NULL, -- 'reflection' or 'mosque'
      username TEXT NOT NULL,
      content TEXT NOT NULL,
      mosque_name TEXT NULL,
      is_wudu_clean INTEGER DEFAULT 0,
      is_ac_working INTEGER DEFAULT 0,
      is_female_friendly INTEGER DEFAULT 0,
      helpful_count INTEGER DEFAULT 0,
      inspiring_count INTEGER DEFAULT 0,
      useful_count INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // 3. User Streaks Sync Table
  db.run(`
    CREATE TABLE IF NOT EXISTS user_streaks (
      user_id INTEGER PRIMARY KEY,
      count INTEGER DEFAULT 0,
      is_frozen INTEGER DEFAULT 0,
      last_updated_date TEXT,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 4. User Prayer History Sync Table
  db.run(`
    CREATE TABLE IF NOT EXISTS user_history (
      user_id INTEGER,
      date TEXT,
      fajr_done INTEGER DEFAULT 0,
      dzuhur_done INTEGER DEFAULT 0,
      ashar_done INTEGER DEFAULT 0,
      maghrib_done INTEGER DEFAULT 0,
      isha_done INTEGER DEFAULT 0,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (user_id, date),
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 5. User Qada Sync Table
  db.run(`
    CREATE TABLE IF NOT EXISTS user_qada (
      uuid TEXT PRIMARY KEY,
      user_id INTEGER,
      prayer_name TEXT,
      date_missed TEXT,
      is_completed INTEGER DEFAULT 0,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  `);

  // 6. Community Comments Table
  db.run(`
    CREATE TABLE IF NOT EXISTS community_comments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      post_id INTEGER NOT NULL,
      username TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(post_id) REFERENCES community_posts(id) ON DELETE CASCADE
    )
  `);

  // 7. Community Replies Table
  db.run(`
    CREATE TABLE IF NOT EXISTS community_replies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      comment_id INTEGER NOT NULL,
      username TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(comment_id) REFERENCES community_comments(id) ON DELETE CASCADE
    )
  `);

  // Safe schema updates for existing databases
  db.serialize(() => {
    db.run("ALTER TABLE community_posts ADD COLUMN event_name TEXT", (err) => {});
    db.run("ALTER TABLE community_posts ADD COLUMN event_date TEXT", (err) => {});
    db.run("ALTER TABLE community_posts ADD COLUMN event_location TEXT", (err) => {});
    db.run("ALTER TABLE community_posts ADD COLUMN comment_count INTEGER DEFAULT 0", (err) => {});
    db.run("ALTER TABLE community_posts ADD COLUMN image_paths TEXT", (err) => {});
    db.run("UPDATE community_posts SET post_type = 'event' WHERE post_type = 'discussion'", (err) => {});
  });

  console.log('Database tables initialized.');
}

// Authentication Middleware using session_token
function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ status: 'error', message: 'No authorization header' });
  }

  const token = authHeader.split(' ')[1];
  if (!token) {
    return res.status(401).json({ status: 'error', message: 'Token format is Bearer <token>' });
  }

  db.get('SELECT * FROM users WHERE session_token = ?', [token], (err, user) => {
    if (err) {
      return res.status(500).json({ status: 'error', message: 'Database error during auth' });
    }
    if (!user) {
      return res.status(401).json({ status: 'error', message: 'Invalid session token' });
    }
    req.user = user;
    next();
  });
}

// JSON Parsing & Serialization Helpers
function safeJsonParse(str, fallback = []) {
  if (!str) return fallback;
  try {
    if (typeof str !== 'string') return str;
    if (str === '[object Object]') return fallback;
    return JSON.parse(str);
  } catch (e) {
    console.error('Failed to parse JSON string:', str, e);
    // If it's a comma-separated list of paths or single path
    if (str && typeof str === 'string' && !str.startsWith('[') && !str.startsWith('{')) {
      return str.split(',').map(s => s.trim()).filter(Boolean);
    }
    return fallback;
  }
}

function ensureJsonString(val) {
  if (!val) return null;
  if (typeof val !== 'string') {
    return JSON.stringify(val);
  }
  try {
    JSON.parse(val);
    return val;
  } catch (e) {
    // If it's a plain string, e.g., "uploads/posts/foo.png", wrap it in an array
    return JSON.stringify([val]);
  }
}

// --- AUTH ROUTERS ---

app.post('/api/auth/register', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ status: 'error', message: 'Username and password required' });
  }

  try {
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);
    const sessionToken = crypto.randomBytes(16).toString('hex');

    db.run(
      `INSERT INTO users (username, password_hash, session_token) VALUES (?, ?, ?)`,
      [username, passwordHash, sessionToken],
      function (err) {
        if (err) {
          if (err.message.includes('UNIQUE constraint failed')) {
            return res.status(400).json({ status: 'error', message: 'Username already exists' });
          }
          return res.status(500).json({ status: 'error', message: 'Registration failed' });
        }
        res.status(201).json({ status: 'success', token: sessionToken, username: username });
      }
    );
  } catch (error) {
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ status: 'error', message: 'Username and password required' });
  }

  db.get('SELECT * FROM users WHERE username = ?', [username], async (err, user) => {
    if (err || !user) {
      return res.status(401).json({ status: 'error', message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ status: 'error', message: 'Invalid credentials' });
    }

    const sessionToken = crypto.randomBytes(16).toString('hex');
    db.run('UPDATE users SET session_token = ? WHERE id = ?', [sessionToken, user.id], (upErr) => {
      if (upErr) {
        return res.status(500).json({ status: 'error', message: 'Token update failed' });
      }
      res.status(200).json({ status: 'success', token: sessionToken, username: username });
    });
  });
});

app.post('/api/auth/update', authenticate, async (req, res) => {
  const { username, password } = req.body;
  const userId = req.user.id;

  if (!username && !password) {
    return res.status(400).json({ status: 'error', message: 'Username or password required to update' });
  }

  try {
    let passwordHash = null;
    if (password) {
      const salt = await bcrypt.genSalt(10);
      passwordHash = await bcrypt.hash(password, salt);
    }

    if (username && passwordHash) {
      db.run(
        `UPDATE users SET username = ?, password_hash = ? WHERE id = ?`,
        [username, passwordHash, userId],
        function (err) {
          if (err) {
            if (err.message.includes('UNIQUE constraint failed')) {
              return res.status(400).json({ status: 'error', message: 'Username already exists' });
            }
            return res.status(500).json({ status: 'error', message: 'Failed to update username and password' });
          }
          res.status(200).json({ status: 'success', message: 'Profile updated successfully', username: username });
        }
      );
    } else if (username) {
      db.run(
        `UPDATE users SET username = ? WHERE id = ?`,
        [username, userId],
        function (err) {
          if (err) {
            if (err.message.includes('UNIQUE constraint failed')) {
              return res.status(400).json({ status: 'error', message: 'Username already exists' });
            }
            return res.status(500).json({ status: 'error', message: 'Failed to update username' });
          }
          res.status(200).json({ status: 'success', message: 'Username updated successfully', username: username });
        }
      );
    } else if (passwordHash) {
      db.run(
        `UPDATE users SET password_hash = ? WHERE id = ?`,
        [passwordHash, userId],
        function (err) {
          if (err) {
            return res.status(500).json({ status: 'error', message: 'Failed to update password' });
          }
          res.status(200).json({ status: 'success', message: 'Password updated successfully' });
        }
      );
    }
  } catch (error) {
    res.status(500).json({ status: 'error', message: 'Internal server error' });
  }
});

// --- SYNC ENGINE (DOUBLE MERGE) ---

app.post('/api/sync', authenticate, (req, res) => {
  const userId = req.user.id;
  const { streak, history, qada } = req.body;

  db.serialize(() => {
    // 1. Merge Streak
    if (streak) {
      db.run(
        `INSERT OR REPLACE INTO user_streaks (user_id, count, is_frozen, last_updated_date) VALUES (?, ?, ?, ?)`,
        [userId, streak.count, streak.is_frozen ? 1 : 0, streak.last_updated_date]
      );
    }

    // 2. Merge History
    if (history && Array.isArray(history)) {
      for (const h of history) {
        db.run(
          `INSERT OR REPLACE INTO user_history (user_id, date, fajr_done, dzuhur_done, ashar_done, maghrib_done, isha_done) VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [
            userId,
            h.date,
            h.fajr_done ? 1 : 0,
            h.dzuhur_done ? 1 : 0,
            h.ashar_done ? 1 : 0,
            h.maghrib_done ? 1 : 0,
            h.isha_done ? 1 : 0
          ]
        );
      }
    }

    // 3. Merge Qada
    if (qada && Array.isArray(qada)) {
      for (const q of qada) {
        db.run(
          `INSERT OR REPLACE INTO user_qada (uuid, user_id, prayer_name, date_missed, is_completed) VALUES (?, ?, ?, ?, ?)`,
          [q.uuid, userId, q.prayer_name, q.date_missed, q.is_completed ? 1 : 0]
        );
      }
    }
  });

  // Pull Consolidated Data
  db.get('SELECT * FROM user_streaks WHERE user_id = ?', [userId], (err, dbStreak) => {
    db.all('SELECT * FROM user_history WHERE user_id = ? ORDER BY date DESC LIMIT 30', [userId], (err, dbHistory) => {
      db.all('SELECT * FROM user_qada WHERE user_id = ?', [userId], (err, dbQada) => {
        
        const finalStreak = dbStreak ? {
          count: dbStreak.count,
          is_frozen: dbStreak.is_frozen === 1,
          last_updated_date: dbStreak.last_updated_date
        } : { count: 0, is_frozen: false, last_updated_date: '' };

        const finalHistory = dbHistory.map(h => ({
          date: h.date,
          fajr_done: h.fajr_done === 1,
          dzuhur_done: h.dzuhur_done === 1,
          ashar_done: h.ashar_done === 1,
          maghrib_done: h.maghrib_done === 1,
          isha_done: h.isha_done === 1
        }));

        const finalQada = dbQada.map(q => ({
          uuid: q.uuid,
          prayer_name: q.prayer_name,
          date_missed: q.date_missed,
          is_completed: q.is_completed === 1
        }));

        res.status(200).json({
          status: 'success',
          streak: finalStreak,
          history: finalHistory,
          qada: finalQada
        });
      });
    });
  });
});

// --- COMMUNITY BOARD API ---

app.get('/api/posts', (req, res) => {
  const limit = parseInt(req.query.limit, 10) || 50;
  const types = req.query.types ? req.query.types.split(',') : [];

  let query = 'SELECT * FROM community_posts';
  const params = [];

  if (types.length > 0) {
    const placeholders = types.map(() => '?').join(',');
    query += ` WHERE post_type IN (${placeholders})`;
    params.push(...types);
  }

  query += ' ORDER BY created_at DESC LIMIT ?';
  params.push(limit);

  db.all(query, params, (err, posts) => {
    if (err) {
      return res.status(500).json({ status: 'error', message: 'Failed to retrieve posts' });
    }
    
    // Map integers to boolean for wudu/ac/female review and parse image_paths JSON
    const formatted = posts.map(p => ({
      ...p,
      is_wudu_clean: p.is_wudu_clean === 1,
      is_ac_working: p.is_ac_working === 1,
      is_female_friendly: p.is_female_friendly === 1,
      image_paths: safeJsonParse(p.image_paths)
    }));
    
    res.status(200).json(formatted);
  });
});

app.get('/api/posts/:id', (req, res) => {
  const postId = req.params.id;
  db.get('SELECT * FROM community_posts WHERE id = ?', [postId], (err, post) => {
    if (err) {
      return res.status(500).json({ status: 'error', message: 'Failed to retrieve post' });
    }
    if (!post) {
      return res.status(404).json({ status: 'error', message: 'Post not found' });
    }
    res.status(200).json({
      ...post,
      is_wudu_clean: post.is_wudu_clean === 1,
      is_ac_working: post.is_ac_working === 1,
      is_female_friendly: post.is_female_friendly === 1,
      image_paths: safeJsonParse(post.image_paths)
    });
  });
});

app.post('/api/posts', authenticate, (req, res) => {
  const { post_type, content, mosque_name, is_wudu_clean, is_ac_working, is_female_friendly, event_name, event_date, event_location, image_paths } = req.body;
  const username = req.user.username;

  if (!post_type || !content) {
    return res.status(400).json({ status: 'error', message: 'Post type and content are required' });
  }

  const sql = `
    INSERT INTO community_posts 
    (post_type, username, content, mosque_name, is_wudu_clean, is_ac_working, is_female_friendly, event_name, event_date, event_location, image_paths) 
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  const finalImagePaths = ensureJsonString(image_paths);

  db.run(
    sql,
    [
      post_type,
      username,
      content,
      mosque_name || null,
      is_wudu_clean ? 1 : 0,
      is_ac_working ? 1 : 0,
      is_female_friendly ? 1 : 0,
      event_name || null,
      event_date || null,
      event_location || null,
      finalImagePaths
    ],
    function (err) {
      if (err) {
        return res.status(500).json({ status: 'error', message: 'Failed to insert post' });
      }
      
      // Get the newly inserted post
      db.get('SELECT * FROM community_posts WHERE id = ?', [this.lastID], (err, post) => {
        if (err || !post) {
          return res.status(500).json({ status: 'error', message: 'Failed to retrieve new post' });
        }
        res.status(201).json({
          ...post,
          is_wudu_clean: post.is_wudu_clean === 1,
          is_ac_working: post.is_ac_working === 1,
          is_female_friendly: post.is_female_friendly === 1,
          image_paths: safeJsonParse(post.image_paths)
        });
      });
    }
  );
});

app.post('/api/posts/:id/react', (req, res) => {
  const postId = req.params.id;
  const { reaction_type } = req.body;

  if (!['helpful', 'inspiring', 'useful'].includes(reaction_type)) {
    return res.status(400).json({ status: 'error', message: 'Invalid reaction type' });
  }

  const columnName = `${reaction_type}_count`;
  const sql = `UPDATE community_posts SET ${columnName} = ${columnName} + 1 WHERE id = ?`;

  db.run(sql, [postId], function (err) {
    if (err) {
      return res.status(500).json({ status: 'error', message: 'Failed to update reaction' });
    }
    
    db.get('SELECT * FROM community_posts WHERE id = ?', [postId], (err, post) => {
      if (err || !post) {
        return res.status(500).json({ status: 'error', message: 'Failed to retrieve post after reaction' });
      }
      res.status(200).json({
        id: post.id,
        helpful_count: post.helpful_count,
        inspiring_count: post.inspiring_count,
        useful_count: post.useful_count
      });
    });
  });
});

// --- COMMENTS & REPLIES API ---

app.get('/api/posts/:id/comments', (req, res) => {
  const postId = req.params.id;
  
  db.all('SELECT * FROM community_comments WHERE post_id = ? ORDER BY created_at ASC', [postId], (err, comments) => {
    if (err) {
      return res.status(500).json({ status: 'error', message: 'Failed to retrieve comments' });
    }
    if (comments.length === 0) {
      return res.status(200).json([]);
    }
    
    const commentIds = comments.map(c => c.id);
    const placeholders = commentIds.map(() => '?').join(',');
    
    db.all(`SELECT * FROM community_replies WHERE comment_id IN (${placeholders}) ORDER BY created_at ASC`, commentIds, (err, replies) => {
      if (err) {
        return res.status(500).json({ status: 'error', message: 'Failed to retrieve replies' });
      }
      
      const repliesMap = {};
      replies.forEach(r => {
        if (!repliesMap[r.comment_id]) {
          repliesMap[r.comment_id] = [];
        }
        repliesMap[r.comment_id].push(r);
      });
      
      const formatted = comments.map(c => ({
        ...c,
        replies: repliesMap[c.id] || []
      }));
      
      res.status(200).json(formatted);
    });
  });
});

app.post('/api/posts/:id/comments', authenticate, (req, res) => {
  const postId = req.params.id;
  const { content } = req.body;
  const username = req.user.username;

  if (!content) {
    return res.status(400).json({ status: 'error', message: 'Comment content is required' });
  }

  db.run(
    'INSERT INTO community_comments (post_id, username, content) VALUES (?, ?, ?)',
    [postId, username, content],
    function (err) {
      if (err) {
        return res.status(500).json({ status: 'error', message: 'Failed to add comment' });
      }
      const commentId = this.lastID;
      
      // Update comment_count in community_posts
      db.run('UPDATE community_posts SET comment_count = comment_count + 1 WHERE id = ?', [postId], (err) => {
        if (err) {
          console.error('Failed to update comment count:', err);
        }
        
        db.get('SELECT * FROM community_comments WHERE id = ?', [commentId], (err, comment) => {
          if (err || !comment) {
            return res.status(500).json({ status: 'error', message: 'Failed to retrieve new comment' });
          }
          res.status(201).json({
            status: 'success',
            comment: {
              ...comment,
              replies: []
            }
          });
        });
      });
    }
  );
});

app.delete('/api/comments/:id', authenticate, (req, res) => {
  const commentId = req.params.id;
  const username = req.user.username;

  db.get('SELECT * FROM community_comments WHERE id = ?', [commentId], (err, comment) => {
    if (err) {
      return res.status(500).json({ status: 'error', message: 'Database error' });
    }
    if (!comment) {
      return res.status(404).json({ status: 'error', message: 'Comment not found' });
    }
    
    // Check if the user is the owner
    if (comment.username !== username) {
      return res.status(403).json({ status: 'error', message: 'Unauthorized to delete this comment' });
    }

    db.get('SELECT COUNT(*) as count FROM community_replies WHERE comment_id = ?', [commentId], (err, row) => {
      const replyCount = row ? row.count : 0;
      const decrementAmount = 1 + replyCount;
      
      db.run('DELETE FROM community_comments WHERE id = ?', [commentId], function (err) {
        if (err) {
          return res.status(500).json({ status: 'error', message: 'Failed to delete comment' });
        }
        
        db.run('UPDATE community_posts SET comment_count = MAX(0, comment_count - ?) WHERE id = ?', [decrementAmount, comment.post_id], (err) => {
          res.status(200).json({ status: 'success', message: 'Comment deleted' });
        });
      });
    });
  });
});

app.post('/api/comments/:id/replies', authenticate, (req, res) => {
  const commentId = req.params.id;
  const { content } = req.body;
  const username = req.user.username;

  if (!content) {
    return res.status(400).json({ status: 'error', message: 'Reply content is required' });
  }

  db.get('SELECT * FROM community_comments WHERE id = ?', [commentId], (err, comment) => {
    if (err) {
      return res.status(500).json({ status: 'error', message: 'Database error' });
    }
    if (!comment) {
      return res.status(404).json({ status: 'error', message: 'Comment not found' });
    }

    db.run(
      'INSERT INTO community_replies (comment_id, username, content) VALUES (?, ?, ?)',
      [commentId, username, content],
      function (err) {
        if (err) {
          return res.status(500).json({ status: 'error', message: 'Failed to add reply' });
        }
        const replyId = this.lastID;

        // Update comment_count in community_posts
        db.run('UPDATE community_posts SET comment_count = comment_count + 1 WHERE id = ?', [comment.post_id], (err) => {
          if (err) {
            console.error('Failed to update comment count for reply:', err);
          }

          db.get('SELECT * FROM community_replies WHERE id = ?', [replyId], (err, reply) => {
            if (err || !reply) {
              return res.status(500).json({ status: 'error', message: 'Failed to retrieve new reply' });
            }
            res.status(201).json({
              status: 'success',
              reply: reply
            });
          });
        });
      }
    );
  });
});

app.delete('/api/replies/:id', authenticate, (req, res) => {
  const replyId = req.params.id;
  const username = req.user.username;

  db.get(
    'SELECT r.*, c.post_id FROM community_replies r JOIN community_comments c ON r.comment_id = c.id WHERE r.id = ?',
    [replyId],
    (err, reply) => {
      if (err) {
        return res.status(500).json({ status: 'error', message: 'Database error' });
      }
      if (!reply) {
        return res.status(404).json({ status: 'error', message: 'Reply not found' });
      }

      if (reply.username !== username) {
        return res.status(403).json({ status: 'error', message: 'Unauthorized to delete this reply' });
      }

      db.run('DELETE FROM community_replies WHERE id = ?', [replyId], function (err) {
        if (err) {
          return res.status(500).json({ status: 'error', message: 'Failed to delete reply' });
        }

        db.run('UPDATE community_posts SET comment_count = MAX(0, comment_count - 1) WHERE id = ?', [reply.post_id], (err) => {
          res.status(200).json({ status: 'success', message: 'Reply deleted' });
        });
      });
    }
  );
});

app.put('/api/posts/:id', authenticate, (req, res) => {
  const postId = req.params.id;
  const username = req.user.username;
  const { content, mosque_name, is_wudu_clean, is_ac_working, is_female_friendly, event_name, event_date, event_location, image_paths } = req.body;

  db.get('SELECT * FROM community_posts WHERE id = ?', [postId], (err, post) => {
    if (err) return res.status(500).json({ status: 'error', message: 'Database error' });
    if (!post) return res.status(404).json({ status: 'error', message: 'Post not found' });
    if (post.username !== username) return res.status(403).json({ status: 'error', message: 'Unauthorized' });

    const sql = `
      UPDATE community_posts 
      SET content = ?,
          mosque_name = ?,
          is_wudu_clean = ?,
          is_ac_working = ?,
          is_female_friendly = ?,
          event_name = ?,
          event_date = ?,
          event_location = ?,
          image_paths = ?
      WHERE id = ?
    `;
    const finalImagePaths = image_paths !== undefined ? ensureJsonString(image_paths) : post.image_paths;
    
    db.run(sql, [
      content || post.content,
      mosque_name !== undefined ? mosque_name : post.mosque_name,
      is_wudu_clean !== undefined ? (is_wudu_clean ? 1 : 0) : post.is_wudu_clean,
      is_ac_working !== undefined ? (is_ac_working ? 1 : 0) : post.is_ac_working,
      is_female_friendly !== undefined ? (is_female_friendly ? 1 : 0) : post.is_female_friendly,
      event_name !== undefined ? event_name : post.event_name,
      event_date !== undefined ? event_date : post.event_date,
      event_location !== undefined ? event_location : post.event_location,
      finalImagePaths,
      postId
    ], function(err) {
      if (err) return res.status(500).json({ status: 'error', message: 'Failed to update post' });
      res.status(200).json({ status: 'success', message: 'Post updated' });
    });
  });
});

app.delete('/api/posts/:id', authenticate, (req, res) => {
  const postId = req.params.id;
  const username = req.user.username;

  db.get('SELECT * FROM community_posts WHERE id = ?', [postId], (err, post) => {
    if (err) return res.status(500).json({ status: 'error', message: 'Database error' });
    if (!post) return res.status(404).json({ status: 'error', message: 'Post not found' });
    if (post.username !== username) return res.status(403).json({ status: 'error', message: 'Unauthorized' });

    db.run('DELETE FROM community_posts WHERE id = ?', [postId], function(err) {
      if (err) return res.status(500).json({ status: 'error', message: 'Failed to delete post' });
      res.status(200).json({ status: 'success', message: 'Post deleted' });
    });
  });
});

// Endpoint to upload a single image from mobile client
app.post('/api/upload', authenticate, upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ status: 'error', message: 'No file uploaded' });
  }
  const relativePath = `uploads/posts/${req.file.filename}`;
  res.status(200).json({
    status: 'success',
    path: relativePath
  });
});

app.listen(PORT, () => {
  console.log(`WAQT Backend API Server running on port ${PORT}`);
});
