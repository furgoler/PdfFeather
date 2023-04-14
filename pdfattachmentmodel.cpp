/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation
*/

#include "pdfattachmentmodel.h"

/*
 * PdfAttachmentModel QT Model for QML ListView
 *
 * When adding/removing items QT has to being notified via:
 *     beginRemoveRows and endRemoveRows for removals
 *     beginInsertRows and endInsertRows for insertions
 *     beginResetModel and endResetModel for resetting the whole data;
 *     emit dataChanged for existing data updates
 *
*/

PdfAttachmentModel::PdfAttachmentModel(QObject *parent)
    : QAbstractListModel{parent}
{
}

PdfAttachmentModel::~PdfAttachmentModel()
{
}

QList<QString> PdfAttachmentModel::getData()
{
    return m_data;
}

int PdfAttachmentModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    // return our data count
    return m_data.count();
}

QVariant PdfAttachmentModel::data(const QModelIndex &index, int role) const
{
    // the index returns the requested row and column information.
    // we ignore the column and only use the row information
    int row = index.row();

    // boundary check for the row
    if(row < 0 || row >= m_data.count())
    {
        return QVariant();
    }

    // A model can return data for different roles.
    switch(role)
    {
        case Qt::DisplayRole: // ("model.display" in QML)
            return m_data.value(row);
    }

    // The view asked for other data, just return an empty QVariant
    return QVariant();
}

void PdfAttachmentModel::clear()
{
    beginResetModel();
    m_data.clear();
    endResetModel();
}

void PdfAttachmentModel::append(const QString &item)
{
    beginInsertRows(QModelIndex(), m_data.count(), m_data.count());
    m_data.append(item);
    endInsertRows();
}

void PdfAttachmentModel::appendList(const QList<QString> &items)
{
    beginInsertRows(QModelIndex(), m_data.count(), m_data.count() + items.size() - 1);
    m_data.append(items);
    endInsertRows();
}

void PdfAttachmentModel::insert(const QString &item, int pos)
{
    beginInsertRows(QModelIndex(), pos, pos);
    m_data.insert(pos, item);
    endInsertRows();
}

void PdfAttachmentModel::remove(int pos)
{
    if (pos >= 0 && pos < m_data.count())
    {
        beginRemoveRows(QModelIndex(), pos, pos);
        m_data.removeAt(pos);
        endRemoveRows ();
    }
}

void PdfAttachmentModel::removeByKey(const QString key)
{
    int pos;
    pos = m_data.indexOf(key);
    if (pos >= 0) remove(pos);
}

void PdfAttachmentModel::replace (const QString &item, int pos)
{
    if (pos >= 0 && pos < m_data.count())
    {
        m_data.replace(pos, item);
        QModelIndex item_index = index(pos, 0);
        emit dataChanged (item_index, item_index);
    }
}

