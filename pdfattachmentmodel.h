/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation
*/

#ifndef PDFATTACHMENTMODEL_H
#define PDFATTACHMENTMODEL_H

#include <QObject>
#include <QString>
#include <QList>
#include <QAbstractListModel>
#include <QModelIndex>

class PdfAttachmentModel : public QAbstractListModel
{
    Q_OBJECT

public:
    explicit PdfAttachmentModel(QObject *parent = nullptr);
    ~PdfAttachmentModel();    

public:
    // QAbstractItemModel interface
    virtual int rowCount(const QModelIndex &parent) const;
    virtual QVariant data(const QModelIndex &index, int role) const;

public slots:
    QList<QString> getData();
    void clear();
    void append(const QString &item);
    void appendList(const QList<QString> &items);
    void insert(const QString &item, int pos);
    void remove(int pos);
    void removeByKey(const QString key);
    void replace (const QString &item, int pos);

private:
    QList<QString> m_data;  // Model/view data
};

#endif // PDFATTACHMENTS_H
