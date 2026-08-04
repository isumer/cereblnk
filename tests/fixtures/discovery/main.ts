import { ipcMain } from 'electron';
ipcMain.handle('ping', () => 'pong');
