<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateWaqtTables extends Migration
{
    public function up()
    {
        // Disable foreign key checks to prevent issues during table creation
        $this->db->disableForeignKeyChecks();

        // 1. Users Table
        $this->forge->addField([
            'id' => [
                'type'           => 'INT',
                'constraint'     => 11,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'username' => [
                'type'       => 'VARCHAR',
                'constraint' => '100',
            ],
            'password_hash' => [
                'type'       => 'VARCHAR',
                'constraint' => '255',
            ],
            'session_token' => [
                'type'       => 'VARCHAR',
                'constraint' => '255',
                'null'       => true,
            ],
            'created_at datetime default current_timestamp',
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addUniqueKey('username');
        $this->forge->createTable('users', true);

        // 2. Community Posts Table
        $this->forge->addField([
            'id' => [
                'type'           => 'INT',
                'constraint'     => 11,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'post_type' => [
                'type'       => 'VARCHAR',
                'constraint' => '50',
            ],
            'username' => [
                'type'       => 'VARCHAR',
                'constraint' => '100',
            ],
            'content' => [
                'type' => 'TEXT',
            ],
            'mosque_name' => [
                'type'       => 'VARCHAR',
                'constraint' => '255',
                'null'       => true,
            ],
            'is_wudu_clean' => [
                'type'       => 'TINYINT',
                'constraint' => 1,
                'default'    => 0,
            ],
            'is_ac_working' => [
                'type'       => 'TINYINT',
                'constraint' => 1,
                'default'    => 0,
            ],
            'is_female_friendly' => [
                'type'       => 'TINYINT',
                'constraint' => 1,
                'default'    => 0,
            ],
            'helpful_count' => [
                'type'       => 'INT',
                'constraint' => 11,
                'default'    => 0,
            ],
            'inspiring_count' => [
                'type'       => 'INT',
                'constraint' => 11,
                'default'    => 0,
            ],
            'useful_count' => [
                'type'       => 'INT',
                'constraint' => 11,
                'default'    => 0,
            ],
            'event_name' => [
                'type'       => 'VARCHAR',
                'constraint' => '255',
                'null'       => true,
            ],
            'event_date' => [
                'type'       => 'VARCHAR',
                'constraint' => '100',
                'null'       => true,
            ],
            'event_location' => [
                'type'       => 'VARCHAR',
                'constraint' => '255',
                'null'       => true,
            ],
            'comment_count' => [
                'type'       => 'INT',
                'constraint' => 11,
                'default'    => 0,
            ],
            'image_paths' => [
                'type' => 'TEXT',
                'null' => true,
            ],
            'created_at datetime default current_timestamp',
        ]);
        $this->forge->addKey('id', true);
        $this->forge->createTable('community_posts', true);

        // 3. User Streaks Table
        $this->forge->addField([
            'user_id' => [
                'type'       => 'INT',
                'constraint' => 11,
                'unsigned'   => true,
            ],
            'count' => [
                'type'       => 'INT',
                'constraint' => 11,
                'default'    => 0,
            ],
            'is_frozen' => [
                'type'       => 'TINYINT',
                'constraint' => 1,
                'default'    => 0,
            ],
            'last_updated_date' => [
                'type'       => 'VARCHAR',
                'constraint' => '50',
                'null'       => true,
            ],
            'updated_at datetime default current_timestamp on update current_timestamp',
        ]);
        $this->forge->addKey('user_id', true);
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('user_streaks', true);

        // 4. User History Table
        $this->forge->addField([
            'user_id' => [
                'type'       => 'INT',
                'constraint' => 11,
                'unsigned'   => true,
            ],
            'date' => [
                'type'       => 'VARCHAR',
                'constraint' => '50',
            ],
            'fajr_done' => [
                'type'       => 'TINYINT',
                'constraint' => 1,
                'default'    => 0,
            ],
            'dzuhur_done' => [
                'type'       => 'TINYINT',
                'constraint' => 1,
                'default'    => 0,
            ],
            'ashar_done' => [
                'type'       => 'TINYINT',
                'constraint' => 1,
                'default'    => 0,
            ],
            'maghrib_done' => [
                'type'       => 'TINYINT',
                'constraint' => 1,
                'default'    => 0,
            ],
            'isha_done' => [
                'type'       => 'TINYINT',
                'constraint' => 1,
                'default'    => 0,
            ],
            'updated_at datetime default current_timestamp on update current_timestamp',
        ]);
        $this->forge->addKey(['user_id', 'date'], true);
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('user_history', true);

        // 5. User Qada Table
        $this->forge->addField([
            'uuid' => [
                'type'       => 'VARCHAR',
                'constraint' => '100',
            ],
            'user_id' => [
                'type'       => 'INT',
                'constraint' => 11,
                'unsigned'   => true,
            ],
            'prayer_name' => [
                'type'       => 'VARCHAR',
                'constraint' => '50',
            ],
            'date_missed' => [
                'type'       => 'VARCHAR',
                'constraint' => '50',
            ],
            'is_completed' => [
                'type'       => 'TINYINT',
                'constraint' => 1,
                'default'    => 0,
            ],
            'updated_at datetime default current_timestamp on update current_timestamp',
        ]);
        $this->forge->addKey('uuid', true);
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('user_qada', true);

        // 6. Community Comments Table
        $this->forge->addField([
            'id' => [
                'type'           => 'INT',
                'constraint'     => 11,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'post_id' => [
                'type'       => 'INT',
                'constraint' => 11,
                'unsigned'   => true,
            ],
            'username' => [
                'type'       => 'VARCHAR',
                'constraint' => '100',
            ],
            'content' => [
                'type' => 'TEXT',
            ],
            'created_at datetime default current_timestamp',
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('post_id', 'community_posts', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('community_comments', true);

        // 7. Community Replies Table
        $this->forge->addField([
            'id' => [
                'type'           => 'INT',
                'constraint'     => 11,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'comment_id' => [
                'type'       => 'INT',
                'constraint' => 11,
                'unsigned'   => true,
            ],
            'username' => [
                'type'       => 'VARCHAR',
                'constraint' => '100',
            ],
            'content' => [
                'type' => 'TEXT',
            ],
            'created_at datetime default current_timestamp',
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('comment_id', 'community_comments', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('community_replies', true);

        // Re-enable foreign key checks
        $this->db->enableForeignKeyChecks();
    }

    public function down()
    {
        $this->db->disableForeignKeyChecks();

        $this->forge->dropTable('community_replies', true);
        $this->forge->dropTable('community_comments', true);
        $this->forge->dropTable('user_qada', true);
        $this->forge->dropTable('user_history', true);
        $this->forge->dropTable('user_streaks', true);
        $this->forge->dropTable('community_posts', true);
        $this->forge->dropTable('users', true);

        $this->db->enableForeignKeyChecks();
    }
}
