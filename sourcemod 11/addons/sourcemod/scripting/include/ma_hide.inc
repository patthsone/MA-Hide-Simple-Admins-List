#if defined _ma_hide_included
  #endinput
#endif
#define _ma_hide_included

/**
 * Проверяет, скрыт ли клиент (использует sm_hide из плагина MA Hide).
 *
 * @param client    Индекс клиента.
 * @return          true если скрыт, false в противном случае.
 */
native bool MA_IsClientHidden(int client);