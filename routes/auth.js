const express = require('express');
const router = express.Router();
const { getPool, sql } = require('../config/database');

/**
 * POST /api/login
 * Kullanıcı giriş işlemi
 * Body: { email: string, password: string }
 */
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  // Validasyon
  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Email ve şifre gereklidir'
    });
  }

  try {
    const pool = await getPool();
    
    // GetRoleNameByEmailAndPassword stored procedure'ünü çağır
    const request = pool.request();
    request.input('Email', sql.NVarChar(100), email.trim());
    request.input('Password', sql.NVarChar(250), password);

    // Stored procedure'ü çağır
    const result = await request.execute('GetRoleNameByEmailAndPassword');

    // Stored procedure sonucunu kontrol et
    if (!result.recordset || result.recordset.length === 0) {
      console.log('❌ No result from stored procedure');
      return res.status(401).json({
        success: false,
        message: 'Kullanıcı adı veya şifre yanlış'
      });
    }

    const roleData = result.recordset[0];
    // Farklı kolon adı olasılıklarını kontrol et
    const roleName = roleData.RoleName || 
                     roleData.roleName || 
                     roleData.Role_Name ||
                     roleData.ROLE_NAME ||
                     null;

    // UserID'yi Users tablosundan al
    const userRequest = pool.request();
    userRequest.input('email', sql.NVarChar(100), email.trim());
    userRequest.input('password', sql.NVarChar(250), password);
    
    const userResult = await userRequest.query(`
      SELECT UserID
      FROM GeneralCommon.Users
      WHERE Email = @email AND Password = @password
    `);

    const userId = userResult.recordset.length > 0 ? userResult.recordset[0].UserID : null;

    console.log('🔍 Login Info:');
    console.log('  Email:', email);
    console.log('  RoleName:', roleName);
    console.log('  UserID:', userId);
    console.log('  RoleData keys:', Object.keys(roleData));

    // RoleName yoksa hata döndür
    if (!roleName) {
      console.log('❌ RoleName not found in result');
      return res.status(401).json({
        success: false,
        message: 'Kullanıcı rolü bulunamadı'
      });
    }

    // Başarılı giriş - RoleName ve UserID'yi döndürüyoruz
    res.json({
      success: true,
      message: 'Giriş başarılı',
      data: {
        roleName: roleName,
        userId: userId // UserID'yi de döndürüyoruz
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

/**
 * POST /api/logout
 * Kullanıcı çıkış işlemi
 * Body: { userId: number }
 */
router.post('/logout', async (req, res) => {
  const { userId } = req.body;

  // Validasyon
  if (!userId || isNaN(userId)) {
    return res.status(400).json({
      success: false,
      message: 'UserID gereklidir'
    });
  }

  try {
    const pool = await getPool();
    
    // LogUserLogout stored procedure'ünü çağır
    const request = pool.request();
    request.input('UserID', sql.Int, parseInt(userId));

    // Stored procedure'ü çağır
    await request.execute('LogUserLogout');

    console.log('✅ Logout logged for UserID:', userId);

    // Başarılı çıkış
    res.json({
      success: true,
      message: 'Çıkış başarılı ve loglandı'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası: ' + error.message
    });
  }
});

module.exports = router;

