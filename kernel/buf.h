struct buf {
  int valid;   // has data been read from disk?
  int disk;    // does disk "own" buf?
  uint dev;
  uint blockno;
  struct sleeplock lock;
  uint refcnt; // used to decide when to move to the head of the LRU list
  struct buf *prev; // LRU cache list
  struct buf *next;
  uchar data[BSIZE];

  uint timestamp;
};

