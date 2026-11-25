// Voto a stelle delle sezioni (ricordi, ristoranti provati): "★★★☆☆".
// Un solo modulo per tutte le sezioni che mostrano un voto da 1 a 5.

String tripSectionStars(int rating) => '★' * rating + '☆' * (5 - rating);
